// ── END-TO-END TEST: Step 2 — Complete Installation ──
Asset beforeInstall = [SELECT Id, Name, Status FROM Asset WHERE Id = '02iaj000002m5XJAAY'];
System.debug('BEFORE INSTALL: ' + beforeInstall.Name + ' Status = ' + beforeInstall.Status);

VDD_CompleteInstallation.Request req2 = new VDD_CompleteInstallation.Request();
req2.assetId = '02iaj000002m5XJAAY';
List<VDD_CompleteInstallation.Response> res2 = VDD_CompleteInstallation.execute(new List<VDD_CompleteInstallation.Request>{req2});
System.debug('STEP 2 RESULT: ' + res2[0].message);
System.assert(res2[0].success, 'Step 2 failed: ' + res2[0].message);

// Verify status
Asset afterInstall = [SELECT Status, InstallDate, Last_Ping__c FROM Asset WHERE Id = '02iaj000002m5XJAAY'];
System.debug('AFTER INSTALL: Status = ' + afterInstall.Status + ', InstallDate = ' + afterInstall.InstallDate + ', Last_Ping = ' + afterInstall.Last_Ping__c);
System.assert(afterInstall.Status == 'Installed', 'Expected Installed, got ' + afterInstall.Status);

// Verify AssetAttributes created
List<AssetAttribute> attrs = [SELECT AttributeDefinitionId, AttributeValue FROM AssetAttribute WHERE AssetId = '02iaj000002m5XJAAY'];
System.debug('ASSET ATTRIBUTES CREATED: ' + attrs.size());
System.assert(attrs.size() == 7, 'Expected 7 attributes, got ' + attrs.size());
for (AssetAttribute a : attrs) {
    System.debug('  Attr: ' + a.AttributeDefinitionId + ' = ' + a.AttributeValue);
}

// Verify threshold monitors created
List<RecordsetFltrCritMonitor> monitors = [SELECT Name, IsWithinThreshold FROM RecordsetFltrCritMonitor WHERE AssetId = '02iaj000002m5XJAAY'];
System.debug('THRESHOLD MONITORS: ' + monitors.size());
System.assert(monitors.size() == 3, 'Expected 3 monitors, got ' + monitors.size());
for (RecordsetFltrCritMonitor m : monitors) {
    System.debug('  Monitor: ' + m.Name + ' IsWithinThreshold = ' + m.IsWithinThreshold);
}

// Verify Flow 2 task
List<Task> installTasks = [SELECT Subject FROM Task WHERE WhatId = '02iaj000002m5XJAAY' AND Subject LIKE 'VDD Device Installed%' ORDER BY CreatedDate DESC LIMIT 1];
System.debug('FLOW 2 TASK: ' + (installTasks.isEmpty() ? 'NONE' : installTasks[0].Subject));

System.debug('=== STEP 2 PASSED ===');
