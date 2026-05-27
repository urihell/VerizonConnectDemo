/**
 * Queueable that sets the Shipment status to "Delivered" asynchronously.
 *
 * This decouples the heavy record-triggered flow (VDD_Delivery_SMS_Notification)
 * from the Confirm Shipment Delivery button transaction. The button handles
 * the quick DML (ProductTransfers + Assets) and enqueues this job. When this
 * job updates the Shipment, the flow fires in its own async transaction —
 * sending the SMS and creating the Work Order without blocking the UI.
 */
public with sharing class VDD_ShipmentDeliveredQueueable implements Queueable {

    private Id shipmentId;

    public VDD_ShipmentDeliveredQueueable(Id shipmentId) {
        this.shipmentId = shipmentId;
    }

    public void execute(QueueableContext context) {
        Shipment ship = [SELECT Id, Status FROM Shipment WHERE Id = :this.shipmentId LIMIT 1];
        ship.Status = 'Delivered';
        ship.ActualDeliveryDate = Datetime.now();
        update ship;
    }
}
