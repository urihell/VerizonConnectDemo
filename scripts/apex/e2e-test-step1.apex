// ── END-TO-END TEST: Step 1 — Confirm Delivery ──
Asset beforeDelivery = [SELECT Id, Name, Status FROM Asset WHERE Id = '02iaj000002m5XJAAY'];
System.debug('BEFORE DELIVERY: ' + beforeDelivery.Name + ' Status = ' + beforeDelivery.Status);
System.assert(beforeDelivery.Status == 'Shipped', 'Expected Shipped, got ' + beforeDelivery.Status);

VDD_ConfirmDelivery.Request req1 = new VDD_ConfirmDelivery.Request();
req1.assetId = '02iaj000002m5XJAAY';
List<VDD_ConfirmDelivery.Response> res1 = VDD_ConfirmDelivery.execute(new List<VDD_ConfirmDelivery.Request>{req1});
System.debug('STEP 1 RESULT: ' + res1[0].message);
System.assert(res1[0].success, 'Step 1 failed: ' + res1[0].message);

Asset afterDelivery = [SELECT Status FROM Asset WHERE Id = '02iaj000002m5XJAAY'];
System.debug('AFTER DELIVERY: Status = ' + afterDelivery.Status);
System.assert(afterDelivery.Status == 'Delivered', 'Expected Delivered, got ' + afterDelivery.Status);

List<Task> deliveryTasks = [SELECT Subject FROM Task WHERE WhatId = '02iaj000002m5XJAAY' AND Subject LIKE 'VDD%' ORDER BY CreatedDate DESC LIMIT 1];
System.debug('FLOW 1 TASK: ' + (deliveryTasks.isEmpty() ? 'NONE' : deliveryTasks[0].Subject));
System.assert(!deliveryTasks.isEmpty(), 'Flow 1 should have created a delivery task');

System.debug('=== STEP 1 PASSED ===');
