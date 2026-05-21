/**
 * Quick Action: Confirm Shipment Delivery
 * Marks the Shipment as "Delivered", then cascades to set VDD Asset status
 * to "Delivered" — triggering the Delivery Coordination agent flow.
 */
public with sharing class VDD_ConfirmShipmentDelivery {

    public class Request {
        @InvocableVariable(required=true description='Shipment record ID')
        public String shipmentId;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='VDD Confirm Shipment Delivery' description='Marks Shipment as Delivered and triggers asset delivery flow.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // 1. Update Shipment status to Delivered
                Shipment ship = [SELECT Id, ShipToName, Status FROM Shipment WHERE Id = :req.shipmentId LIMIT 1];
                ship.Status = 'Delivered';
                ship.ActualDeliveryDate = Datetime.now();
                update ship;

                // 2. Update ProductTransfers — mark as received
                List<ProductTransfer> transfers = [
                    SELECT Id, QuantitySent, IsReceived
                    FROM ProductTransfer
                    WHERE ShipmentId = :req.shipmentId
                ];
                Integer transferCount = 0;
                if (!transfers.isEmpty()) {
                    for (ProductTransfer pt : transfers) {
                        pt.IsReceived = true;
                        pt.QuantityReceived = pt.QuantitySent;
                        pt.ReceivedById = UserInfo.getUserId();
                    }
                    update transfers;
                    transferCount = transfers.size();
                }

                // 3. Find all ShipmentItems linked to Assets
                List<ShipmentItem> items = [
                    SELECT Id, SDO_OMS_AssetId__c, Product2.Name
                    FROM ShipmentItem
                    WHERE ShipmentId = :req.shipmentId AND SDO_OMS_AssetId__c != null
                ];

                // 4. Cascade asset statuses to Delivered
                Set<Id> assetIds = new Set<Id>();
                for (ShipmentItem si : items) {
                    assetIds.add(si.SDO_OMS_AssetId__c);
                }

                List<Asset> assetsToUpdate = new List<Asset>();
                for (Asset a : [SELECT Id, Name, Status FROM Asset WHERE Id IN :assetIds]) {
                    if (a.Status == 'Shipped') {
                        a.Status = 'Delivered';
                        assetsToUpdate.add(a);
                    }
                }

                if (!assetsToUpdate.isEmpty()) {
                    update assetsToUpdate;
                }

                res.success = true;
                res.message = 'Shipment to ' + ship.ShipToName + ' marked as Delivered. '
                    + transferCount + ' product transfers received. '
                    + assetsToUpdate.size() + ' assets updated. '
                    + 'Delivery Coordination agent will contact the customer to schedule installation.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error confirming shipment delivery: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
