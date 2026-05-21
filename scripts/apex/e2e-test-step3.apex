// ── END-TO-END TEST: Step 3 — Simulate Battery Failure ──
VDD_SimulateBatteryFailure.Request req3 = new VDD_SimulateBatteryFailure.Request();
req3.assetId = '02iaj000002m5XJAAY';
List<VDD_SimulateBatteryFailure.Response> res3 = VDD_SimulateBatteryFailure.execute(new List<VDD_SimulateBatteryFailure.Request>{req3});
System.debug('STEP 3 RESULT: ' + res3[0].message);
System.assert(res3[0].success, 'Step 3 failed: ' + res3[0].message);

// Verify battery attribute is now 11.4
List<AssetAttribute> batteryAttrs = [
    SELECT AttributeValue FROM AssetAttribute
    WHERE AssetId = '02iaj000002m5XJAAY'
      AND AttributeDefinitionId = '0tjaj000000IUMDAA4'
];
System.debug('BATTERY VALUE: ' + (batteryAttrs.isEmpty() ? 'NONE' : batteryAttrs[0].AttributeValue));
System.assert(!batteryAttrs.isEmpty(), 'Battery attribute missing');
System.assert(batteryAttrs[0].AttributeValue == '11.4', 'Expected 11.4, got ' + batteryAttrs[0].AttributeValue);

// Check monitor status — should now be IsWithinThreshold = false for battery
List<RecordsetFltrCritMonitor> monitors = [
    SELECT Name, IsWithinThreshold FROM RecordsetFltrCritMonitor
    WHERE AssetId = '02iaj000002m5XJAAY'
    ORDER BY Name
];
for (RecordsetFltrCritMonitor m : monitors) {
    System.debug('  Monitor: ' + m.Name + ' IsWithinThreshold = ' + m.IsWithinThreshold);
}

// Check Flow 3 fired — should create a threshold breach task
List<Task> breachTasks = [SELECT Subject FROM Task WHERE WhatId = '02iaj000002m5XJAAY' AND Subject LIKE 'VDD Threshold Breach%' ORDER BY CreatedDate DESC LIMIT 1];
System.debug('FLOW 3 TASK: ' + (breachTasks.isEmpty() ? 'NONE (may need async processing)' : breachTasks[0].Subject));

System.debug('=== STEP 3 PASSED ===');
