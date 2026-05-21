// ══════════════════════════════════════════════════════
// VDD FULL END-TO-END DEMO TEST
// Runs all 3 demo steps in sequence and validates results
// ══════════════════════════════════════════════════════

Id vddAssetId = '02iaj000002m5XJAAY';

// ── STEP 1: Confirm Delivery ──
System.debug('══ STEP 1: CONFIRM DELIVERY ══');
VDD_ConfirmDelivery.Request req1 = new VDD_ConfirmDelivery.Request();
req1.assetId = vddAssetId;
List<VDD_ConfirmDelivery.Response> res1 = VDD_ConfirmDelivery.execute(new List<VDD_ConfirmDelivery.Request>{req1});
System.debug('Result: ' + res1[0].message);
System.assert(res1[0].success, 'STEP 1 FAILED: ' + res1[0].message);

Asset afterStep1 = [SELECT Status FROM Asset WHERE Id = :vddAssetId];
System.assert(afterStep1.Status == 'Delivered', 'Status should be Delivered');

List<Task> step1Tasks = [SELECT Subject FROM Task WHERE WhatId = :vddAssetId AND Subject LIKE 'VDD Device Delivered%'];
System.assert(!step1Tasks.isEmpty(), 'Flow 1 delivery task missing');
System.debug('✓ STEP 1 PASSED — Status: Delivered, Flow task created');

// ── STEP 2: Complete Installation ──
System.debug('══ STEP 2: COMPLETE INSTALLATION ══');
VDD_CompleteInstallation.Request req2 = new VDD_CompleteInstallation.Request();
req2.assetId = vddAssetId;
List<VDD_CompleteInstallation.Response> res2 = VDD_CompleteInstallation.execute(new List<VDD_CompleteInstallation.Request>{req2});
System.debug('Result: ' + res2[0].message);
System.assert(res2[0].success, 'STEP 2 FAILED: ' + res2[0].message);

Asset afterStep2 = [SELECT Status, InstallDate FROM Asset WHERE Id = :vddAssetId];
System.assert(afterStep2.Status == 'Installed', 'Status should be Installed');
System.assert(afterStep2.InstallDate == Date.today(), 'InstallDate should be today');

Integer attrCount = [SELECT COUNT() FROM AssetAttribute WHERE AssetId = :vddAssetId];
System.assert(attrCount == 7, 'Expected 7 attrs, got ' + attrCount);

List<RecordsetFltrCritMonitor> monitors = [SELECT Name, IsWithinThreshold FROM RecordsetFltrCritMonitor WHERE AssetId = :vddAssetId ORDER BY Name];
System.assert(monitors.size() == 3, 'Expected 3 monitors, got ' + monitors.size());
for (RecordsetFltrCritMonitor m : monitors) {
    System.debug('  ' + m.Name + ' → IsWithinThreshold = ' + m.IsWithinThreshold);
    System.assert(m.IsWithinThreshold == true, m.Name + ' should be within threshold');
}
System.debug('✓ STEP 2 PASSED — Status: Installed, 7 attrs, 3 monitors (all healthy)');

// ── STEP 3: Simulate Battery Failure ──
System.debug('══ STEP 3: SIMULATE BATTERY FAILURE ══');
VDD_SimulateBatteryFailure.Request req3 = new VDD_SimulateBatteryFailure.Request();
req3.assetId = vddAssetId;
List<VDD_SimulateBatteryFailure.Response> res3 = VDD_SimulateBatteryFailure.execute(new List<VDD_SimulateBatteryFailure.Request>{req3});
System.debug('Result: ' + res3[0].message);
System.assert(res3[0].success, 'STEP 3 FAILED: ' + res3[0].message);

// Verify battery attribute degraded
List<AssetAttribute> batteryAttr = [
    SELECT AttributeValue FROM AssetAttribute
    WHERE AssetId = :vddAssetId AND AttributeDefinitionId = '0tjaj000000IUMDAA4'
];
System.assert(!batteryAttr.isEmpty() && batteryAttr[0].AttributeValue == '11.4', 'Battery should be 11.4V');

// Verify battery monitor is now out of threshold
List<RecordsetFltrCritMonitor> batteryMonitor = [
    SELECT IsWithinThreshold FROM RecordsetFltrCritMonitor
    WHERE AssetId = :vddAssetId AND Name = 'VDD Battery Voltage'
];
System.assert(!batteryMonitor.isEmpty(), 'Battery monitor missing');
System.assert(batteryMonitor[0].IsWithinThreshold == false, 'Battery monitor should be OUT of threshold');

// Verify threshold breach task created with WhatId
List<Task> breachTasks = [SELECT Subject, WhatId FROM Task WHERE Subject LIKE 'VDD Threshold Breach%' AND WhatId = :vddAssetId ORDER BY CreatedDate DESC LIMIT 1];
System.debug('Breach task: ' + (breachTasks.isEmpty() ? 'PENDING (async)' : breachTasks[0].Subject));

System.debug('✓ STEP 3 PASSED — Battery: 11.4V, Monitor: breached');

System.debug('══════════════════════════════════════');
System.debug('  ALL 3 DEMO STEPS PASSED ✓✓✓');
System.debug('══════════════════════════════════════');
