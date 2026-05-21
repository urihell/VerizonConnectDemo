// Create ShipmentItems for all 5 VDD products on the Black Rock Paving shipment
Id shipmentId = '0OBaj0000004tXNGAY';

List<ShipmentItem> items = new List<ShipmentItem>();

// VDD-400 GPS Tracking Unit → Asset VDD-400-BRP-0847
items.add(new ShipmentItem(
    ShipmentId = shipmentId,
    Product2Id = '01taj00000SBBCvAAP',
    Quantity = 1,
    Description = 'VDD-400 GPS Tracking Unit — S/N: VDD4-2026-0847',
    SDO_OMS_AssetId__c = '02iaj000002m5XJAAY'
));

// DC-200 Dual Dashcam → Asset DC-200-BRP-0312
items.add(new ShipmentItem(
    ShipmentId = shipmentId,
    Product2Id = '01taj00000SBBMbAAP',
    Quantity = 1,
    Description = 'DC-200 Dual Dashcam — S/N: DC2-2026-0312',
    SDO_OMS_AssetId__c = '02iaj000002m5YvAAI'
));

// External GPS Antenna → Asset ANT-VDD-0847
items.add(new ShipmentItem(
    ShipmentId = shipmentId,
    Product2Id = '01taj00000SBBPpAAP',
    Quantity = 1,
    Description = 'External GPS Antenna — Component of VDD-400-BRP-0847',
    SDO_OMS_AssetId__c = '02iaj000002m5dlAAA'
));

// OBD-II Y-Harness → Asset HAR-VDD-0847
items.add(new ShipmentItem(
    ShipmentId = shipmentId,
    Product2Id = '01taj00000SB7dyAAD',
    Quantity = 1,
    Description = 'OBD-II Y-Harness — Component of VDD-400-BRP-0847',
    SDO_OMS_AssetId__c = '02iaj000002m5c9AAA'
));

// IoT SIM Card (CAT-M1) → Asset SIM-VDD-0847
items.add(new ShipmentItem(
    ShipmentId = shipmentId,
    Product2Id = '01taj00000SBBODAA5',
    Quantity = 1,
    Description = 'IoT SIM Card (CAT-M1) — Component of VDD-400-BRP-0847',
    SDO_OMS_AssetId__c = '02iaj000002m5aXAAQ'
));

insert items;
System.debug('✓ Created ' + items.size() + ' ShipmentItems');
for (ShipmentItem si : items) {
    System.debug('  ' + si.Id + ' | ' + si.Description);
}
