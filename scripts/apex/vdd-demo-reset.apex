/**
 * VDD Demo Reset Script
 * ---------------------
 * Resets all Verizon Connect Demo (VDD) data for the Black Rock Paving demo
 * to its initial state, ready for a fresh 10-minute walkthrough.
 *
 * Run via:  sf apex run --file scripts/apex/vdd-demo-reset.apex --target-org verizon-connect-bj550e
 *
 * What this script does:
 *   1.  Resets all 38 Asset statuses to demo-start positions
 *   2.  Deletes demo-generated Tasks (VDD flow alerts)
 *   3.  Deletes demo-generated Work Orders tied to VDD assets
 *   4.  Deletes demo-generated Cases tied to VDD assets
 *   5.  Deletes AssetAttribute health metrics
 *   6.  Deletes RecordsetFltrCritMonitor threshold monitors
 *   7.  Clears InstallDate and Last_Ping__c on VDD-400
 *   8.  Resets Shipment SP-0002 to In Transit
 *   9.  Deletes & recreates ProductTransfers (can't update once IsReceived=true)
 *  10.  Deletes VDD Chatter feed posts
 *  11.  Ends open MessagingSessions for Jim Stone (clean SMS state)
 */

// ── 0. Constants ─────────────────────────────────────────────────
Id blackRockAccountId = '001aj00002sRTnPAAW';  // Black Rock Paving
Id shipmentId         = '0OBaj0000004tXNGAY';  // SP-0002

// Demo asset IDs — Original 10 (3-level hierarchy)
// Level 1 – Vehicles
Id semiTruckId       = '02iaj000002m5VhAAI';  // Semi Truck #7 — 2022 Kenworth T680
Id dumpTruckId       = '02iaj000002m5fNAAQ';  // Dump Truck #3 — 2021 Mack Granite
Id excavatorId       = '02iaj000002m5gzAAA';  // Excavator #1 — 2023 CAT 320
Id paverId           = '02iaj000002m5kDAAQ';  // Paver #2 — 2020 Volvo ABG7820C
Id pickupTruckId     = '02iaj000002m5lpAAA';  // Pickup Truck #5 — 2024 Ford F-250
// Level 2 – Equipment (children of Semi Truck #7)
Id vddTrackerId      = '02iaj000002m5XJAAY';  // VDD-400-BRP-0847 (GPS tracker)
Id dashcamId         = '02iaj000002m5YvAAI';  // DC-200-BRP-0312  (dashcam)
// Level 3 – Components (children of VDD-400 tracker)
Id simCardId         = '02iaj000002m5aXAAQ';  // SIM-VDD-0847
Id harnessId         = '02iaj000002m5c9AAA';  // HAR-VDD-0847
Id antennaId         = '02iaj000002m5dlAAA';  // ANT-VDD-0847

// Expanded Fleet — 28 new assets
Id excavator2Id      = '02iaj000002mfAzAAI';  // Excavator #2
Id bulldozer8Id      = '02iaj000002mfB0AAI';  // Bulldozer #8
Id bulldozer9Id      = '02iaj000002mfB1AAI';  // Bulldozer #9
Id roller10Id        = '02iaj000002mfB2AAI';  // Compaction Roller #10
Id roller11Id        = '02iaj000002mfB3AAI';  // Compaction Roller #11
Id loader12Id        = '02iaj000002mfB4AAI';  // Loader #12
Id loader13Id        = '02iaj000002mfB5AAI';  // Loader #13
Id paver14Id         = '02iaj000002mfB6AAI';  // Asphalt Paver #14
Id paver15Id         = '02iaj000002mfB7AAI';  // Asphalt Paver #15
Id miller16Id        = '02iaj000002mfB8AAI';  // Cold Milling Machine #16
Id miller17Id        = '02iaj000002mfB9AAI';  // Cold Milling Machine #17
Id miller18Id        = '02iaj000002mfBAAAY';  // Cold Milling Machine #18
Id sweeper19Id       = '02iaj000002mfBBAAY';  // Sweeper #19
Id sweeper20Id       = '02iaj000002mfBCAAY';  // Sweeper #20
Id paving21Id        = '02iaj000002mfBDAAY';  // Paving Machine #21
Id paving22Id        = '02iaj000002mfBEAAY';  // Paving Machine #22
Id paving23Id        = '02iaj000002mfBFAAY';  // Paving Machine #23
Id flatbed24Id       = '02iaj000002mfBGAAY';  // Heavy-Haul Flatbed #24
Id flatbed25Id       = '02iaj000002mfBHAAY';  // Heavy-Haul Flatbed #25
Id flatbed26Id       = '02iaj000002mfBIAAY';  // Heavy-Haul Flatbed #26
Id flatbed27Id       = '02iaj000002mfBJAAY';  // Heavy-Haul Flatbed #27
Id dump28Id          = '02iaj000002mfBKAAY';  // Dump Truck #28
Id dump29Id          = '02iaj000002mfBLAAY';  // Dump Truck #29
Id semi30Id          = '02iaj000002mfBMAAY';  // Semi Truck #30
Id semi31Id          = '02iaj000002mfBNAAY';  // Semi Truck #31
Id semi32Id          = '02iaj000002mfBOAAY';  // Semi Truck #32
Id crew33Id          = '02iaj000002mfBPAAY';  // Crew Cab #33
Id crew34Id          = '02iaj000002mfBQAAY';  // Crew Cab #34

// All VDD asset IDs for bulk operations
Set<Id> allVddAssetIds = new Set<Id>{
    semiTruckId, dumpTruckId, excavatorId, paverId, pickupTruckId,
    vddTrackerId, dashcamId, simCardId, harnessId, antennaId,
    excavator2Id, bulldozer8Id, bulldozer9Id, roller10Id, roller11Id,
    loader12Id, loader13Id, paver14Id, paver15Id,
    miller16Id, miller17Id, miller18Id, sweeper19Id, sweeper20Id,
    paving21Id, paving22Id, paving23Id,
    flatbed24Id, flatbed25Id, flatbed26Id, flatbed27Id,
    dump28Id, dump29Id, semi30Id, semi31Id, semi32Id,
    crew33Id, crew34Id
};

// ProductTransfer template data (for delete/recreate)
// Product IDs
Id prodGPS     = '01taj00000SBBCvAAP';  // VDD-400 GPS Tracking Unit
Id prodDashcam = '01taj00000SBBMbAAP';  // DC-200 Dual Dashcam
Id prodAntenna = '01taj00000SBBPpAAP';  // External GPS Antenna
Id prodHarness = '01taj00000SB7dyAAD';  // OBD-II Y-Harness
Id prodSIM     = '01taj00000SBBODAA5';  // IoT SIM Card (CAT-M1)
// Locations
Id srcLocation = '131aj000000WVtWAAW';  // Verizon Connect warehouse
Id dstLocation = '131aj000000WfrFAAS';  // Black Rock Paving yard
// ProductRequestLineItem IDs
Id prliGPS     = '0Twaj0000004x4jCAA';  // PRLI-0001
Id prliDashcam = '0Twaj0000004x4kCAA';  // PRLI-0002
Id prliAntenna = '0Twaj0000004x4lCAA';  // PRLI-0003
Id prliHarness = '0Twaj0000004x4mCAA';  // PRLI-0004
Id prliSIM     = '0Twaj0000004x4nCAA';  // PRLI-0005

System.debug('=== VDD DEMO RESET STARTING ===');

// ── 1. Reset Asset Statuses ──────────────────────────────────────
// Semi Truck #7 starts as "Purchased" (demo progresses to Delivered)
// Its child equipment/components start as "Shipped"
// All other vehicles/equipment start as "Installed" (background fleet)
List<Asset> assetsToUpdate = new List<Asset>();

// Demo subject assets
assetsToUpdate.add(new Asset(Id = semiTruckId,   Status = 'Purchased'));
assetsToUpdate.add(new Asset(Id = vddTrackerId,  Status = 'Shipped'));
assetsToUpdate.add(new Asset(Id = dashcamId,     Status = 'Shipped'));
assetsToUpdate.add(new Asset(Id = simCardId,     Status = 'Shipped'));
assetsToUpdate.add(new Asset(Id = harnessId,     Status = 'Shipped'));
assetsToUpdate.add(new Asset(Id = antennaId,     Status = 'Shipped'));

// Background fleet — all "Installed"
for (Id assetId : new List<Id>{
    dumpTruckId, excavatorId, paverId, pickupTruckId,
    excavator2Id, bulldozer8Id, bulldozer9Id, roller10Id, roller11Id,
    loader12Id, loader13Id, paver14Id, paver15Id,
    miller16Id, miller17Id, miller18Id, sweeper19Id, sweeper20Id,
    paving21Id, paving22Id, paving23Id,
    flatbed24Id, flatbed25Id, flatbed26Id, flatbed27Id,
    dump28Id, dump29Id, semi30Id, semi31Id, semi32Id,
    crew33Id, crew34Id
}) {
    assetsToUpdate.add(new Asset(Id = assetId, Status = 'Installed'));
}

update assetsToUpdate;
System.debug('✓ Asset statuses reset: ' + assetsToUpdate.size() + ' assets');

// ── 2. Delete VDD Flow-Generated Tasks ───────────────────────────
List<Task> vddTasks = [
    SELECT Id FROM Task
    WHERE Subject LIKE 'VDD%'
       OR (WhatId IN :allVddAssetIds AND Subject LIKE '%VDD%')
];
if (!vddTasks.isEmpty()) {
    delete vddTasks;
    System.debug('✓ Deleted ' + vddTasks.size() + ' VDD tasks');
} else {
    System.debug('✓ No VDD tasks to delete');
}

// ── 3. Delete Demo-Generated Work Orders ─────────────────────────
List<WorkOrder> vddWorkOrders = [
    SELECT Id FROM WorkOrder
    WHERE AssetId IN :allVddAssetIds
       OR Subject LIKE '%VDD%'
];
if (!vddWorkOrders.isEmpty()) {
    delete vddWorkOrders;
    System.debug('✓ Deleted ' + vddWorkOrders.size() + ' VDD work orders');
} else {
    System.debug('✓ No VDD work orders to delete');
}

// ── 4. Delete Demo-Generated Cases ───────────────────────────────
List<Case> vddCases = [
    SELECT Id FROM Case
    WHERE AssetId IN :allVddAssetIds
       OR Subject LIKE '%VDD%'
];
if (!vddCases.isEmpty()) {
    delete vddCases;
    System.debug('✓ Deleted ' + vddCases.size() + ' VDD cases');
} else {
    System.debug('✓ No VDD cases to delete');
}

// ── 5. Delete AssetAttributes on VDD Assets ────────────────────
List<AssetAttribute> existingAttrs = [
    SELECT Id FROM AssetAttribute
    WHERE AssetId IN :allVddAssetIds
];
if (!existingAttrs.isEmpty()) {
    Database.deleteImmediate(existingAttrs);
    System.debug('✓ Deleted ' + existingAttrs.size() + ' existing asset attributes');
} else {
    System.debug('✓ No asset attributes to delete');
}

// ── 6. Delete RecordsetFltrCritMonitor Thresholds ──────────────
List<RecordsetFltrCritMonitor> existingMonitors = [
    SELECT Id FROM RecordsetFltrCritMonitor
    WHERE AssetId = :vddTrackerId
];
if (!existingMonitors.isEmpty()) {
    delete existingMonitors;
    System.debug('✓ Deleted ' + existingMonitors.size() + ' existing VDD monitors');
} else {
    System.debug('✓ No VDD monitors to delete');
}

// ── 7. Clear InstallDate and Last_Ping__c on VDD-400 ──────────
Asset trackerReset = [SELECT Id, InstallDate, Last_Ping__c FROM Asset WHERE Id = :vddTrackerId LIMIT 1];
trackerReset.InstallDate = null;
trackerReset.Last_Ping__c = null;
update trackerReset;
System.debug('✓ Cleared InstallDate and Last_Ping__c on VDD-400');

// ── 8. Reset Shipment Status to In Transit ─────────────────────
Shipment ship = [SELECT Id, Status, ActualDeliveryDate FROM Shipment WHERE Id = :shipmentId LIMIT 1];
ship.Status = 'In Transit';
ship.ActualDeliveryDate = null;
update ship;
System.debug('✓ Reset Shipment SP-0002 to In Transit (cleared ActualDeliveryDate)');

// ── 9. Delete & Recreate ProductTransfers ──────────────────────
// IMPORTANT: Once IsReceived=true, Salesforce locks the ProductTransfer
// record and prevents updates. We must delete and recreate them.
List<ProductTransfer> existingPTs = [
    SELECT Id FROM ProductTransfer
    WHERE ShipmentId = :shipmentId
];
if (!existingPTs.isEmpty()) {
    delete existingPTs;
    System.debug('✓ Deleted ' + existingPTs.size() + ' locked ProductTransfers');
}

// Recreate fresh ProductTransfers linked to shipment and PR line items
List<ProductTransfer> newPTs = new List<ProductTransfer>();
newPTs.add(new ProductTransfer(
    Product2Id = prodGPS, QuantitySent = 33, QuantityUnitOfMeasure = 'Each',
    SourceLocationId = srcLocation, DestinationLocationId = dstLocation,
    ShipmentId = shipmentId, ProductRequestLineItemId = prliGPS
));
newPTs.add(new ProductTransfer(
    Product2Id = prodDashcam, QuantitySent = 33, QuantityUnitOfMeasure = 'Each',
    SourceLocationId = srcLocation, DestinationLocationId = dstLocation,
    ShipmentId = shipmentId, ProductRequestLineItemId = prliDashcam
));
newPTs.add(new ProductTransfer(
    Product2Id = prodAntenna, QuantitySent = 33, QuantityUnitOfMeasure = 'Each',
    SourceLocationId = srcLocation, DestinationLocationId = dstLocation,
    ShipmentId = shipmentId, ProductRequestLineItemId = prliAntenna
));
newPTs.add(new ProductTransfer(
    Product2Id = prodHarness, QuantitySent = 33, QuantityUnitOfMeasure = 'Each',
    SourceLocationId = srcLocation, DestinationLocationId = dstLocation,
    ShipmentId = shipmentId, ProductRequestLineItemId = prliHarness
));
newPTs.add(new ProductTransfer(
    Product2Id = prodSIM, QuantitySent = 33, QuantityUnitOfMeasure = 'Each',
    SourceLocationId = srcLocation, DestinationLocationId = dstLocation,
    ShipmentId = shipmentId, ProductRequestLineItemId = prliSIM
));
insert newPTs;
System.debug('✓ Created ' + newPTs.size() + ' fresh ProductTransfers');

// ── 10. Delete VDD Chatter Feed Posts on Assets ──────────────────
List<FeedItem> vddFeedItems = [
    SELECT Id, Body FROM FeedItem
    WHERE ParentId IN :allVddAssetIds
];
List<FeedItem> toDeleteFeeds = new List<FeedItem>();
for (FeedItem fi : vddFeedItems) {
    if (fi.Body != null && fi.Body.contains('VDD')) {
        toDeleteFeeds.add(fi);
    }
}
if (!toDeleteFeeds.isEmpty()) {
    delete toDeleteFeeds;
    System.debug('✓ Deleted ' + toDeleteFeeds.size() + ' VDD Chatter feed posts');
} else {
    System.debug('✓ No VDD Chatter feed posts to delete');
}

// ── 11. End Open MessagingSessions for Jim Stone ─────────────────
// Clean SMS state so the outbound notification flow can start fresh
Id jimMessagingUserId = '0PAaj00000C1J3JGAV';
List<MessagingSession> openSessions = [
    SELECT Id, Status FROM MessagingSession
    WHERE MessagingEndUserId = :jimMessagingUserId
      AND Status NOT IN ('Ended', 'Closed')
];
if (!openSessions.isEmpty()) {
    for (MessagingSession ms : openSessions) {
        ms.Status = 'Ended';
    }
    update openSessions;
    System.debug('✓ Ended ' + openSessions.size() + ' open MessagingSessions for Jim Stone');
} else {
    System.debug('✓ No open MessagingSessions to end');
}

System.debug('=== VDD DEMO RESET COMPLETE ===');
System.debug('Demo is ready for a fresh walkthrough:');
System.debug('  • Shipment SP-0002 → In Transit');
System.debug('  • Semi Truck #7 → Purchased (demo subject)');
System.debug('  • VDD-400, DC-200, Components → Shipped');
System.debug('  • 32 fleet vehicles/equipment → Installed');
System.debug('  • VDD-400 health metrics & monitors → Cleared');
System.debug('  • All VDD tasks, work orders, cases → Deleted');
System.debug('  • ProductTransfers → Fresh (not received)');
System.debug('  • VDD Chatter posts → Deleted');
System.debug('  • MessagingSessions → Ended (clean SMS)');
System.debug('');
System.debug('Demo Flow:');
System.debug('  Step 0: Navigate to PR-0003 → Shipment Tracker → Click "Confirm Shipment Delivery"');
System.debug('  Step 1: SMS sends to Jim Stone → Agentforce Service Agent picks up reply');
System.debug('  Step 2: Navigate to VDD-400 Asset → Click "2 - Complete Installation"');
System.debug('  Step 3: Click "3 - Simulate Battery Failure" → Triggers health alert');
