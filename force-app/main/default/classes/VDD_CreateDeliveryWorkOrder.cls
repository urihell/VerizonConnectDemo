/**
 * Auto-creates a Work Order with Work Order Line Items when a Shipment
 * is delivered. Called from the VDD_Delivery_SMS_Notification flow.
 *
 * The Work Order is linked to the Product Request via the standard
 * ProductRequest.WorkOrderId field, assigned the "Installation" Work Type
 * (which auto-creates a Service Appointment), and gets one WOLI per
 * vehicle derived from the ShipmentItems' asset hierarchy.
 *
 * Customer date/time preferences are NOT set here — they are populated
 * later by VDD_CreateInstallerWorkOrder after the Agentforce agent
 * collects them from the customer via SMS.
 */
public with sharing class VDD_CreateDeliveryWorkOrder {

    public class Request {
        @InvocableVariable(required=true description='Shipment record ID')
        public String shipmentId;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public String workOrderId;
    }

    @InvocableMethod(label='VDD Create Delivery Work Order' description='Auto-creates a Work Order with WOLIs for each vehicle when a shipment is delivered.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        // Query the Installation WorkType once
        List<WorkType> workTypes = [
            SELECT Id, Name, EstimatedDuration
            FROM WorkType
            WHERE Name = 'Installation' LIMIT 1
        ];
        Id installationWorkTypeId = workTypes.isEmpty() ? null : workTypes[0].Id;

        // Query the service territory once
        List<ServiceTerritory> territories = [
            SELECT Id FROM ServiceTerritory
            WHERE Name = '*New Jersey' AND IsActive = true LIMIT 1
        ];
        Id serviceTerritoryId = territories.isEmpty() ? null : territories[0].Id;

        for (Request req : requests) {
            Response res = new Response();
            try {
                // 1. Get Shipment with Product Request link
                Shipment ship = [
                    SELECT Id, ShipmentNumber, ShipToName, Status,
                           Product_Request__c, ActualDeliveryDate
                    FROM Shipment
                    WHERE Id = :req.shipmentId LIMIT 1
                ];

                if (ship.Product_Request__c == null) {
                    res.success = false;
                    res.message = 'Shipment ' + ship.ShipmentNumber + ' has no linked Product Request. Cannot create Work Order.';
                    responses.add(res);
                    continue;
                }

                // 2. Get Product Request details + Account address
                ProductRequest pr = [
                    SELECT Id, ProductRequestNumber, AccountId, Account.Name,
                           Account.BillingStreet, Account.BillingCity,
                           Account.BillingState, Account.BillingPostalCode,
                           Account.BillingCountry,
                           DestinationLocationId, WorkOrderId
                    FROM ProductRequest
                    WHERE Id = :ship.Product_Request__c LIMIT 1
                ];

                // Get primary contact for the account
                List<Contact> contacts = [
                    SELECT Id FROM Contact
                    WHERE AccountId = :pr.AccountId
                    ORDER BY CreatedDate ASC LIMIT 1
                ];
                Id primaryContactId = contacts.isEmpty() ? null : contacts[0].Id;

                // 3. Duplicate check — if PR already has a WO, skip
                if (pr.WorkOrderId != null) {
                    res.success = true;
                    res.workOrderId = pr.WorkOrderId;
                    res.message = 'Work Order already exists for this Product Request. Skipping creation.';
                    responses.add(res);
                    continue;
                }

                // 4. Derive vehicles from ShipmentItems' asset hierarchy
                //    Get all ShipmentItem assets for this shipment
                List<ShipmentItem> shipItems = [
                    SELECT Id, SDO_OMS_AssetId__c
                    FROM ShipmentItem
                    WHERE ShipmentId = :req.shipmentId
                      AND SDO_OMS_AssetId__c != null
                ];

                Set<Id> shipAssetIds = new Set<Id>();
                for (ShipmentItem si : shipItems) {
                    shipAssetIds.add(si.SDO_OMS_AssetId__c);
                }

                // Query these assets with their parent chain
                Map<Id, Asset> assetMap = new Map<Id, Asset>([
                    SELECT Id, Name, ParentId, Parent.ParentId
                    FROM Asset
                    WHERE Id IN :shipAssetIds
                ]);

                // Walk up to root vehicle for each asset
                // A root vehicle is an asset with ParentId = null
                Set<Id> vehicleIds = new Set<Id>();
                for (Asset a : assetMap.values()) {
                    Id rootId = findRootVehicle(a, assetMap);
                    if (rootId != null) {
                        vehicleIds.add(rootId);
                    }
                }

                // Query the unique vehicle assets
                List<Asset> vehicleAssets = [
                    SELECT Id, Name FROM Asset
                    WHERE Id IN :vehicleIds
                    ORDER BY Name
                ];

                // 5. Build descriptive subject and description
                String deliveryDate = ship.ActualDeliveryDate != null
                    ? ship.ActualDeliveryDate.format('yyyy-MM-dd')
                    : String.valueOf(Date.today());

                String woSubject = 'VDD-400 Fleet Installation — ' + pr.Account.Name;

                String woDescription = 'INSTALLATION WORK ORDER\n' +
                    '========================\n\n' +
                    'Customer: ' + pr.Account.Name + '\n' +
                    'Product Request: ' + pr.ProductRequestNumber + '\n' +
                    'Equipment Delivered: ' + deliveryDate + '\n' +
                    'Vehicles to Install: ' + vehicleAssets.size() + '\n\n' +
                    'SCOPE OF WORK:\n' +
                    'Install VDD-400 GPS Tracking Units on all fleet vehicles.\n' +
                    'Each vehicle requires:\n' +
                    '  1. OBD-II Y-Harness connection to vehicle diagnostic port\n' +
                    '  2. VDD-400 unit mounted under dashboard\n' +
                    '  3. External GPS antenna routed to windshield mount\n' +
                    '  4. Wiring harness connected to vehicle power\n' +
                    '  5. GPS lock and cellular connectivity verification\n' +
                    '  6. Diagnostic test via Verizon Connect portal\n' +
                    '  7. Asset status updated to Installed in Salesforce\n\n' +
                    'VEHICLE LIST:\n';

                for (Integer i = 0; i < vehicleAssets.size(); i++) {
                    woDescription += '  ' + (i + 1) + '. ' + vehicleAssets[i].Name + '\n';
                }

                woDescription += '\nNote: Customer preferred installation dates will be added once confirmed by the Delivery Coordination agent.';

                // 6. Create the Work Order — with Contact and Address
                WorkOrder wo = new WorkOrder(
                    Subject = woSubject,
                    Description = woDescription,
                    AccountId = pr.AccountId,
                    ContactId = primaryContactId,
                    WorkTypeId = installationWorkTypeId,
                    LocationId = pr.DestinationLocationId,
                    ServiceTerritoryId = serviceTerritoryId,
                    Street = pr.Account.BillingStreet,
                    City = pr.Account.BillingCity,
                    State = pr.Account.BillingState,
                    PostalCode = pr.Account.BillingPostalCode,
                    Country = pr.Account.BillingCountry,
                    Priority = 'Medium',
                    Status = 'New',
                    StartDate = System.now(),
                    EndDate = System.now().addDays(14)
                );
                insert wo;

                // Re-query to get WorkOrderNumber
                wo = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id = :wo.Id LIMIT 1];

                // 7. Link the ProductRequest to this Work Order
                pr.WorkOrderId = wo.Id;
                update pr;

                // 8. Create Work Order Line Items — one per vehicle
                List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
                for (Asset vehicle : vehicleAssets) {
                    wolis.add(new WorkOrderLineItem(
                        WorkOrderId = wo.Id,
                        AssetId = vehicle.Id,
                        Subject = 'Install VDD-400 on ' + vehicle.Name,
                        Description = 'Install and configure VDD-400 GPS tracking device on ' + vehicle.Name + '.\n' +
                            'Steps: Mount unit, connect OBD-II harness, route antenna, verify connectivity.',
                        WorkTypeId = installationWorkTypeId,
                        Status = 'New'
                    ));
                }

                if (!wolis.isEmpty()) {
                    insert wolis;
                }

                res.success = true;
                res.workOrderId = wo.Id;
                res.message = 'Work Order ' + wo.WorkOrderNumber + ' created for ' + pr.Account.Name +
                    ' with ' + wolis.size() + ' installation line items (one per vehicle). ' +
                    'Linked to Product Request ' + pr.ProductRequestNumber + '. ' +
                    'Work Type: Installation. Territory: ' + (serviceTerritoryId != null ? '*New Jersey' : 'Unassigned') + '.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error creating delivery work order: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }

    /**
     * Walk up the parent chain to find the root vehicle (asset with no parent).
     * Handles up to 3 levels deep: Component → VDD-400 → Vehicle
     */
    private static Id findRootVehicle(Asset a, Map<Id, Asset> assetMap) {
        // If this asset has no parent, it IS the vehicle
        if (a.ParentId == null) return a.Id;

        // Check parent — if parent has no parent, parent is the vehicle
        if (a.Parent != null && a.Parent.ParentId == null) return a.ParentId;

        // Grandparent level — component → VDD → vehicle
        if (a.Parent != null && a.Parent.ParentId != null) {
            // Query grandparent if needed
            Asset parent = assetMap.get(a.ParentId);
            if (parent != null && parent.ParentId != null) {
                return parent.ParentId;
            }
            return a.Parent.ParentId;
        }

        // Fallback — return the parent
        return a.ParentId;
    }
}
