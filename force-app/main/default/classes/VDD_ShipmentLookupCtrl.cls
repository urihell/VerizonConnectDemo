/**
 * Apex controller for the VDD Product Request Tracker LWC.
 * Fetches the Shipment linked to a Product Request via Product_Request__c.
 */
public with sharing class VDD_ShipmentLookupCtrl {

    public class ShipmentData {
        @AuraEnabled public String shipmentId;
        @AuraEnabled public String shipmentNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String shipToName;
        @AuraEnabled public String trackingNumber;
        @AuraEnabled public String trackingUrl;
        @AuraEnabled public String provider;
        @AuraEnabled public String expectedDeliveryDate;
        @AuraEnabled public String actualDeliveryDate;
        @AuraEnabled public String shipFromAddress;
        @AuraEnabled public String shipToAddress;
    }

    @AuraEnabled(cacheable=true)
    public static ShipmentData getShipmentForProductRequest(String productRequestId) {
        List<Shipment> ships = [
            SELECT Id, ShipmentNumber, Status, ShipToName,
                   TrackingNumber, TrackingUrl, Provider,
                   ExpectedDeliveryDate, ActualDeliveryDate,
                   ShipFromStreet, ShipFromCity, ShipFromState,
                   ShipToStreet, ShipToCity, ShipToState
            FROM Shipment
            WHERE Product_Request__c = :productRequestId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (ships.isEmpty()) {
            return null;
        }

        Shipment s = ships[0];
        ShipmentData data = new ShipmentData();
        data.shipmentId = s.Id;
        data.shipmentNumber = s.ShipmentNumber;
        data.status = s.Status;
        data.shipToName = s.ShipToName;
        data.trackingNumber = s.TrackingNumber;
        data.trackingUrl = s.TrackingUrl;
        data.provider = s.Provider;
        data.expectedDeliveryDate = s.ExpectedDeliveryDate != null
            ? s.ExpectedDeliveryDate.format('EEE, MMM d') : null;
        data.actualDeliveryDate = s.ActualDeliveryDate != null
            ? s.ActualDeliveryDate.format('EEE, MMM d h:mm a') : null;

        String fromParts = '';
        if (s.ShipFromStreet != null) fromParts += s.ShipFromStreet;
        if (s.ShipFromCity != null) fromParts += (fromParts.length() > 0 ? ', ' : '') + s.ShipFromCity;
        if (s.ShipFromState != null) fromParts += (fromParts.length() > 0 ? ', ' : '') + s.ShipFromState;
        data.shipFromAddress = fromParts;

        String toParts = '';
        if (s.ShipToStreet != null) toParts += s.ShipToStreet;
        if (s.ShipToCity != null) toParts += (toParts.length() > 0 ? ', ' : '') + s.ShipToCity;
        if (s.ShipToState != null) toParts += (toParts.length() > 0 ? ', ' : '') + s.ShipToState;
        data.shipToAddress = toParts;

        return data;
    }

    /**
     * Confirms delivery of a Shipment — delegates to VDD_ConfirmShipmentDelivery.
     * Callable from LWC (non-cacheable @AuraEnabled).
     */
    @AuraEnabled
    public static String confirmDelivery(String shipmentId) {
        VDD_ConfirmShipmentDelivery.Request req = new VDD_ConfirmShipmentDelivery.Request();
        req.shipmentId = shipmentId;
        List<VDD_ConfirmShipmentDelivery.Response> results =
            VDD_ConfirmShipmentDelivery.execute(new List<VDD_ConfirmShipmentDelivery.Request>{ req });
        if (!results.isEmpty() && results[0].success) {
            return results[0].message;
        }
        throw new AuraHandledException(
            results.isEmpty() ? 'No response from delivery confirmation.' : results[0].message
        );
    }
}
