/**
 * Quick Action: Confirm Shipment Delivery
 *
 * Handles ProductTransfer receipts and Asset status cascades synchronously
 * (fast operations), then enqueues the Shipment status update to run
 * asynchronously. This lets the UI return immediately while the heavy
 * record-triggered flow (SMS notification + Work Order creation) fires
 * in a separate background transaction.
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
                // 1. Query the Shipment (but don't update it yet — that's async)
                Shipment ship = [SELECT Id, ShipToName, Status FROM Shipment WHERE Id = :req.shipmentId LIMIT 1];

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

                // 5. Enqueue the Shipment status update to run asynchronously.
                //    When the Shipment status changes to "Delivered", the
                //    VDD_Delivery_SMS_Notification flow fires in a separate
                //    transaction — sending the SMS and creating the Work Order
                //    without blocking this button.
                System.enqueueJob(new VDD_ShipmentDeliveredQueueable(ship.Id));

                res.success = true;
                res.message = 'Shipment to ' + ship.ShipToName + ' confirmed. '
                    + transferCount + ' product transfers received. '
                    + assetsToUpdate.size() + ' assets updated to Delivered. '
                    + 'SMS notification and Work Order creation are processing in the background.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error confirming shipment delivery: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
