// Create ProductItems at warehouse + ProductTransfers for all VDD products
Id warehouseId = '131aj000000WVtWAAW';   // Warehouse Distribution Center
Id destId = '131aj000000WfrFAAS';        // Black Rock Paving — Fleet Yard
Id shipmentId = '0OBaj0000004tXNGAY';    // Existing Shipment

// Products
Id vdd400   = '01taj00000SBBCvAAP';  // VDD-400 GPS Tracking Unit
Id dc200    = '01taj00000SBBMbAAP';  // DC-200 Dual Dashcam
Id antenna  = '01taj00000SBBPpAAP';  // External GPS Antenna
Id harness  = '01taj00000SB7dyAAD';  // OBD-II Y-Harness
Id simCard  = '01taj00000SBBODAA5';  // IoT SIM Card (CAT-M1)

// 1. Create ProductItems at warehouse (inventory)
List<ProductItem> items = new List<ProductItem>();
items.add(new ProductItem(Product2Id = vdd400,  LocationId = warehouseId, QuantityOnHand = 25, QuantityUnitOfMeasure = 'Each'));
items.add(new ProductItem(Product2Id = dc200,   LocationId = warehouseId, QuantityOnHand = 30, QuantityUnitOfMeasure = 'Each'));
items.add(new ProductItem(Product2Id = antenna, LocationId = warehouseId, QuantityOnHand = 50, QuantityUnitOfMeasure = 'Each'));
items.add(new ProductItem(Product2Id = harness, LocationId = warehouseId, QuantityOnHand = 40, QuantityUnitOfMeasure = 'Each'));
items.add(new ProductItem(Product2Id = simCard, LocationId = warehouseId, QuantityOnHand = 100, QuantityUnitOfMeasure = 'Each'));
insert items;
System.debug('✓ Created ' + items.size() + ' ProductItems at warehouse');

// 2. We already have a PT for VDD-400 (0Luaj000008rq0fCAA). Create PTs for the other 4.
List<ProductTransfer> transfers = new List<ProductTransfer>();
transfers.add(new ProductTransfer(
    SourceLocationId = warehouseId,
    DestinationLocationId = destId,
    Product2Id = dc200,
    QuantitySent = 1,
    ShipmentId = shipmentId,
    Description = 'DC-200 Dual Dashcam for Black Rock Paving Semi Truck #7'
));
transfers.add(new ProductTransfer(
    SourceLocationId = warehouseId,
    DestinationLocationId = destId,
    Product2Id = antenna,
    QuantitySent = 1,
    ShipmentId = shipmentId,
    Description = 'External GPS Antenna for VDD-400-BRP-0847'
));
transfers.add(new ProductTransfer(
    SourceLocationId = warehouseId,
    DestinationLocationId = destId,
    Product2Id = harness,
    QuantitySent = 1,
    ShipmentId = shipmentId,
    Description = 'OBD-II Y-Harness for VDD-400-BRP-0847'
));
transfers.add(new ProductTransfer(
    SourceLocationId = warehouseId,
    DestinationLocationId = destId,
    Product2Id = simCard,
    QuantitySent = 1,
    ShipmentId = shipmentId,
    Description = 'IoT SIM Card (CAT-M1) for VDD-400-BRP-0847'
));
insert transfers;
System.debug('✓ Created ' + transfers.size() + ' additional ProductTransfers');

// 3. Verify all transfers on this shipment
List<ProductTransfer> allPTs = [
    SELECT ProductTransferNumber, Product2.Name, ShipmentStatus, QuantitySent
    FROM ProductTransfer WHERE ShipmentId = :shipmentId
];
System.debug('All ProductTransfers on shipment:');
for (ProductTransfer pt : allPTs) {
    System.debug('  ' + pt.ProductTransferNumber + ' | ' + pt.Product2.Name + ' | Qty: ' + pt.QuantitySent + ' | Status: ' + pt.ShipmentStatus);
}
