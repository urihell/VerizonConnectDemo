// Link Shipment SP-0002 and ProductTransfers to Product Request PR-0003
Id shipmentId = '0OBaj0000004tXNGAY';
Id productRequestId = '0TSaj0000009V4bGAE';

// 1. Update Shipment → Product Request
Shipment ship = [SELECT Id, Product_Request__c FROM Shipment WHERE Id = :shipmentId LIMIT 1];
ship.Product_Request__c = productRequestId;
update ship;
System.debug('✓ Linked Shipment SP-0002 → Product Request PR-0003');

// 2. Link ProductTransfers to ProductRequestLineItems via matching Product2Id
List<ProductTransfer> transfers = [SELECT Id, ProductTransferNumber, Product2Id FROM ProductTransfer WHERE ShipmentId = :shipmentId];
List<ProductRequestLineItem> lineItems = [SELECT Id, Product2Id FROM ProductRequestLineItem WHERE ParentId = :productRequestId];

// Build a map: Product2Id → PRLI Id
Map<Id, Id> productToPRLI = new Map<Id, Id>();
for (ProductRequestLineItem prli : lineItems) {
    productToPRLI.put(prli.Product2Id, prli.Id);
}

Integer linked = 0;
for (ProductTransfer pt : transfers) {
    if (productToPRLI.containsKey(pt.Product2Id)) {
        pt.ProductRequestLineItemId = productToPRLI.get(pt.Product2Id);
        linked++;
    }
}
update transfers;
System.debug('✓ Linked ' + linked + ' ProductTransfers → ProductRequestLineItems');

// 3. Set the SourceLocation on the ProductRequest (Warehouse)
ProductRequest pr = [SELECT Id, SourceLocationId FROM ProductRequest WHERE Id = :productRequestId LIMIT 1];
pr.SourceLocationId = '131aj000000WVtWAAW';  // Warehouse Distribution Center
update pr;
System.debug('✓ Set SourceLocation on PR-0003 to Warehouse Distribution Center');
