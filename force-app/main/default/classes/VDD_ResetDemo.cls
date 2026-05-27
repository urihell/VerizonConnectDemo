/**
 * VDD Demo Reset — Invocable Apex
 * Resets all Verizon Connect Demo data for the Black Rock Paving demo
 * to its initial state, ready for a fresh 10-minute walkthrough.
 *
 * Covers all assets (vehicles + device kits), shipment, product transfers
 * (delete/recreate to bypass platform lock on received transfers),
 * messaging sessions, work orders, service appointments, and all
 * demo-generated records (tasks, cases, asset attributes, monitors).
 *
 * IMPORTANT: Deletion steps run BEFORE asset status changes to prevent
 * record-triggered flows from firing during cleanup (e.g., threshold
 * breach alerts, installed/delivered SMS notifications).
 */
public with sharing class VDD_ResetDemo {

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='VDD Reset Demo' description='Resets the entire VDD demo to initial state.')
    public static List<Response> execute(List<SObject> unused) {
        List<Response> responses = new List<Response>();
        Response res = new Response();
        try {
            res.message = runReset();
            res.success = true;
        } catch (Exception e) {
            res.success = false;
            res.message = 'Reset error: ' + e.getMessage();
        }
        responses.add(res);
        return responses;
    }

    public static String runReset() {
        // ── Constants ──
        Id shipmentId = '0OBaj0000004tXNGAY';   // SP-0002
        Id accountId  = '001aj00002sRTnPAAW';    // Black Rock Paving
        Id productRequestId = '0TSaj0000009V4bGAE'; // PR-0003

        // Original 10 assets (Semi Truck #7 kit)
        Id semiTruckId   = '02iaj000002m5VhAAI';
        Id dumpTruckId   = '02iaj000002m5fNAAQ';
        Id excavatorId   = '02iaj000002m5gzAAA';
        Id paverId       = '02iaj000002m5kDAAQ';
        Id pickupTruckId = '02iaj000002m5lpAAA';
        Id vddTrackerId  = '02iaj000002m5XJAAY';
        Id dashcamId     = '02iaj000002m5YvAAI';
        Id simCardId     = '02iaj000002m5aXAAQ';
        Id harnessId     = '02iaj000002m5c9AAA';
        Id antennaId     = '02iaj000002m5dlAAA';

        // Expanded fleet 28 vehicle assets
        List<Id> fleetIds = new List<Id>{
            '02iaj000002mfAzAAI', '02iaj000002mfB0AAI', '02iaj000002mfB1AAI',
            '02iaj000002mfB2AAI', '02iaj000002mfB3AAI', '02iaj000002mfB4AAI',
            '02iaj000002mfB5AAI', '02iaj000002mfB6AAI', '02iaj000002mfB7AAI',
            '02iaj000002mfB8AAI', '02iaj000002mfB9AAI', '02iaj000002mfBAAAY',
            '02iaj000002mfBBAAY', '02iaj000002mfBCAAY', '02iaj000002mfBDAAY',
            '02iaj000002mfBEAAY', '02iaj000002mfBFAAY', '02iaj000002mfBGAAY',
            '02iaj000002mfBHAAY', '02iaj000002mfBIAAY', '02iaj000002mfBJAAY',
            '02iaj000002mfBKAAY', '02iaj000002mfBLAAY', '02iaj000002mfBMAAY',
            '02iaj000002mfBNAAY', '02iaj000002mfBOAAY', '02iaj000002mfBPAAY',
            '02iaj000002mfBQAAY'
        };

        // Start with original + fleet vehicle assets
        Set<Id> allVddAssetIds = new Set<Id>{
            semiTruckId, dumpTruckId, excavatorId, paverId, pickupTruckId,
            vddTrackerId, dashcamId, simCardId, harnessId, antennaId
        };
        allVddAssetIds.addAll(fleetIds);

        // Dynamically add ALL device assets (Telematics + Components) for the account
        // This captures the 160 device assets (VDD-400s, DC-200s, antennas, harnesses, SIMs)
        for (Asset a : [
            SELECT Id FROM Asset
            WHERE AccountId = :accountId
              AND Product2.Family IN ('Telematics', 'Components')
        ]) {
            allVddAssetIds.add(a.Id);
        }

        List<String> log = new List<String>();

        // ════════════════════════════════════════════════════════════
        // PHASE 1: DELETE all demo-generated records BEFORE changing
        //          asset statuses. This prevents record-triggered
        //          flows from firing during cleanup.
        // ════════════════════════════════════════════════════════════

        // ── 1. Delete Monitors on ALL VDD assets (not just tracker) ──
        List<RecordsetFltrCritMonitor> monitors = [
            SELECT Id FROM RecordsetFltrCritMonitor WHERE AssetId IN :allVddAssetIds
        ];
        if (!monitors.isEmpty()) { delete monitors; log.add(monitors.size() + ' monitors deleted'); }

        // ── 2. Delete Tasks ──
        List<Task> tasks = [SELECT Id FROM Task WHERE Subject LIKE 'VDD%' OR (WhatId IN :allVddAssetIds AND Subject LIKE '%VDD%')];
        if (!tasks.isEmpty()) { delete tasks; log.add(tasks.size() + ' tasks deleted'); }

        // ── 3a. Delete Service Appointments linked to VDD Work Orders ──
        List<WorkOrder> existingWOs = [SELECT Id FROM WorkOrder WHERE AssetId IN :allVddAssetIds OR Subject LIKE '%VDD%'];
        if (!existingWOs.isEmpty()) {
            Set<Id> woIds = new Set<Id>();
            for (WorkOrder wo : existingWOs) { woIds.add(wo.Id); }
            List<ServiceAppointment> sas = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId IN :woIds];
            if (!sas.isEmpty()) { delete sas; log.add(sas.size() + ' service appointments deleted'); }
        }

        // ── 3b. Delete Work Orders ──
        if (!existingWOs.isEmpty()) { delete existingWOs; log.add(existingWOs.size() + ' work orders deleted'); }

        // ── 3c. Clear ProductRequest.WorkOrderId (set by VDD_CreateDeliveryWorkOrder) ──
        try {
            ProductRequest pr = [SELECT Id, WorkOrderId FROM ProductRequest WHERE Id = :productRequestId LIMIT 1];
            if (pr.WorkOrderId != null) {
                pr.WorkOrderId = null;
                update pr;
                log.add('ProductRequest WorkOrderId cleared');
            }
        } catch (Exception e) {
            log.add('ProductRequest reset skipped: ' + e.getMessage());
        }

        // ── 4. Delete Cases ──
        List<Case> cases = [SELECT Id FROM Case WHERE AssetId IN :allVddAssetIds OR Subject LIKE '%VDD%'];
        if (!cases.isEmpty()) { delete cases; log.add(cases.size() + ' cases deleted'); }

        // ── 5. Delete AssetAttributes ──
        List<AssetAttribute> attrs = [SELECT Id FROM AssetAttribute WHERE AssetId IN :allVddAssetIds];
        if (!attrs.isEmpty()) { Database.deleteImmediate(attrs); log.add(attrs.size() + ' asset attributes deleted'); }

        // ── 6. Delete Chatter Posts ──
        List<FeedItem> feeds = [SELECT Id, Body FROM FeedItem WHERE ParentId IN :allVddAssetIds];
        List<FeedItem> vddFeeds = new List<FeedItem>();
        for (FeedItem fi : feeds) {
            if (fi.Body != null && fi.Body.contains('VDD')) { vddFeeds.add(fi); }
        }
        if (!vddFeeds.isEmpty()) { delete vddFeeds; log.add(vddFeeds.size() + ' Chatter posts deleted'); }

        // ── 7. End Open MessagingSessions ──
        try {
            Set<Id> jimMsgUsers = new Set<Id>{'0PAaj00000C1J3JGAV', '0PAaj00000C2cezGAB'};
            List<MessagingSession> sessions = [
                SELECT Id, Status FROM MessagingSession
                WHERE MessagingEndUserId IN :jimMsgUsers AND Status NOT IN ('Ended', 'Closed')
            ];
            if (!sessions.isEmpty()) {
                for (MessagingSession ms : sessions) { ms.Status = 'Ended'; }
                update sessions;
                log.add(sessions.size() + ' messaging sessions ended');
            }
        } catch (Exception e) {
            log.add('MessagingSessions skipped: ' + e.getMessage());
        }

        // ════════════════════════════════════════════════════════════
        // PHASE 2: RESET asset statuses & related objects.
        //          All cleanup is done — flows that fire now will
        //          only create the expected demo-state records.
        // ════════════════════════════════════════════════════════════

        // ── 8. Reset Asset Statuses (includes tracker field clear) ──
        // Merge tracker field clear into the same DML to avoid a
        // second update that re-triggers the Installed flow.
        // Reset ALL assets in allVddAssetIds to Shipped in one bulk update.
        Set<Id> processedIds = new Set<Id>();
        List<Asset> assetsToUpdate = new List<Asset>();

        // Tracker: set to Shipped AND clear fields in ONE update
        Asset trackerReset = new Asset(Id = vddTrackerId, Status = 'Shipped');
        trackerReset.InstallDate = null;
        trackerReset.put('Last_Ping__c', null);
        assetsToUpdate.add(trackerReset);
        processedIds.add(vddTrackerId);

        // All remaining VDD assets → Shipped
        for (Id assetId : allVddAssetIds) {
            if (!processedIds.contains(assetId)) {
                assetsToUpdate.add(new Asset(Id = assetId, Status = 'Shipped'));
                processedIds.add(assetId);
            }
        }
        update assetsToUpdate;
        log.add(assetsToUpdate.size() + ' assets reset');

        // ── 9. Reset Shipment ──
        Shipment ship = [SELECT Id, Status, ActualDeliveryDate FROM Shipment WHERE Id = :shipmentId LIMIT 1];
        ship.Status = 'In Transit';
        ship.ActualDeliveryDate = null;
        update ship;
        log.add('Shipment SP-0002 → In Transit');

        // ── 10. Delete & Recreate ProductTransfers ──
        List<ProductTransfer> existingPTs = [SELECT Id FROM ProductTransfer WHERE ShipmentId = :shipmentId];
        if (!existingPTs.isEmpty()) { delete existingPTs; }

        Id prodGPS     = '01taj00000SBBCvAAP';
        Id prodDashcam = '01taj00000SBBMbAAP';
        Id prodAntenna = '01taj00000SBBPpAAP';
        Id prodHarness = '01taj00000SB7dyAAD';
        Id prodSIM     = '01taj00000SBBODAA5';
        Id srcLoc      = '131aj000000WVtWAAW';
        Id dstLoc      = '131aj000000WfrFAAS';
        Id prliGPS     = '0Twaj0000004x4jCAA';
        Id prliDashcam = '0Twaj0000004x4kCAA';
        Id prliAntenna = '0Twaj0000004x4lCAA';
        Id prliHarness = '0Twaj0000004x4mCAA';
        Id prliSIM     = '0Twaj0000004x4nCAA';

        List<ProductTransfer> newPTs = new List<ProductTransfer>{
            new ProductTransfer(Product2Id=prodGPS, QuantitySent=33, QuantityUnitOfMeasure='Each',
                SourceLocationId=srcLoc, DestinationLocationId=dstLoc, ShipmentId=shipmentId, ProductRequestLineItemId=prliGPS),
            new ProductTransfer(Product2Id=prodDashcam, QuantitySent=33, QuantityUnitOfMeasure='Each',
                SourceLocationId=srcLoc, DestinationLocationId=dstLoc, ShipmentId=shipmentId, ProductRequestLineItemId=prliDashcam),
            new ProductTransfer(Product2Id=prodAntenna, QuantitySent=33, QuantityUnitOfMeasure='Each',
                SourceLocationId=srcLoc, DestinationLocationId=dstLoc, ShipmentId=shipmentId, ProductRequestLineItemId=prliAntenna),
            new ProductTransfer(Product2Id=prodHarness, QuantitySent=33, QuantityUnitOfMeasure='Each',
                SourceLocationId=srcLoc, DestinationLocationId=dstLoc, ShipmentId=shipmentId, ProductRequestLineItemId=prliHarness),
            new ProductTransfer(Product2Id=prodSIM, QuantitySent=33, QuantityUnitOfMeasure='Each',
                SourceLocationId=srcLoc, DestinationLocationId=dstLoc, ShipmentId=shipmentId, ProductRequestLineItemId=prliSIM)
        };
        insert newPTs;
        log.add('5 ProductTransfers recreated');

        // ── 10b. Reset warehouse ProductItem quantities ──
        Id warehouseLoc = '131aj000000WVtWAAW';
        List<ProductItem> warehouseItems = [
            SELECT Id, ProductName, QuantityOnHand FROM ProductItem
            WHERE LocationId = :warehouseLoc
            AND ProductName IN ('VDD-400 GPS Tracking Unit','DC-200 Dual Dashcam','External GPS Antenna','OBD-II Y-Harness','IoT SIM Card (CAT-M1)')
        ];
        for (ProductItem pi : warehouseItems) { pi.QuantityOnHand = 100; }
        if (!warehouseItems.isEmpty()) { update warehouseItems; log.add('Warehouse ProductItem quantities reset to 100'); }

        // ── 10c. Reset destination ProductItem quantities to 0 ──
        List<ProductItem> destItems = [
            SELECT Id, ProductName, QuantityOnHand FROM ProductItem
            WHERE LocationId = :dstLoc
            AND ProductName IN ('VDD-400 GPS Tracking Unit','DC-200 Dual Dashcam','External GPS Antenna','OBD-II Y-Harness','IoT SIM Card (CAT-M1)')
        ];
        for (ProductItem pi : destItems) { pi.QuantityOnHand = 0; }
        if (!destItems.isEmpty()) { update destItems; log.add('Destination ProductItem quantities reset to 0'); }

        return 'Demo reset complete: ' + String.join(log, '; ');
    }
}