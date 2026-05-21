// Create ProductRequestLineItems for Black Rock Paving order
Id prId = '0TSaj0000009V4bGAE';  // ProductRequest

List<ProductRequestLineItem> lines = new List<ProductRequestLineItem>();

// VDD-400 GPS Tracking Unit
lines.add(new ProductRequestLineItem(
    ParentId = prId,
    Product2Id = '01taj00000SBBCvAAP',
    QuantityRequested = 1,
    QuantityUnitOfMeasure = 'Each',
    Status = 'Submitted'
));

// DC-200 Dual Dashcam
lines.add(new ProductRequestLineItem(
    ParentId = prId,
    Product2Id = '01taj00000SBBMbAAP',
    QuantityRequested = 1,
    QuantityUnitOfMeasure = 'Each',
    Status = 'Submitted'
));

// External GPS Antenna
lines.add(new ProductRequestLineItem(
    ParentId = prId,
    Product2Id = '01taj00000SBBPpAAP',
    QuantityRequested = 1,
    QuantityUnitOfMeasure = 'Each',
    Status = 'Submitted'
));

// OBD-II Y-Harness
lines.add(new ProductRequestLineItem(
    ParentId = prId,
    Product2Id = '01taj00000SB7dyAAD',
    QuantityRequested = 1,
    QuantityUnitOfMeasure = 'Each',
    Status = 'Submitted'
));

// IoT SIM Card (CAT-M1)
lines.add(new ProductRequestLineItem(
    ParentId = prId,
    Product2Id = '01taj00000SBBODAA5',
    QuantityRequested = 1,
    QuantityUnitOfMeasure = 'Each',
    Status = 'Submitted'
));

insert lines;
System.debug('✓ Created ' + lines.size() + ' ProductRequestLineItems');
for (ProductRequestLineItem li : lines) {
    System.debug('  Line: ' + li.Id + ' Product: ' + li.Product2Id);
}
