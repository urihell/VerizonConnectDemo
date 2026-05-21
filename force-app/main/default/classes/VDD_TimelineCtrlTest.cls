@IsTest
private class VDD_TimelineCtrlTest {

    @TestSetup
    static void setupData() {
        Account acct = new Account(Name = 'Test Paving Co');
        insert acct;

        Asset vehicle = new Asset(
            Name = 'Test Semi Truck',
            AccountId = acct.Id,
            Status = 'Installed',
            InstallDate = Date.today().addDays(-3)
        );
        insert vehicle;

        Asset device = new Asset(
            Name = 'VDD-400 Test',
            AccountId = acct.Id,
            ParentId = vehicle.Id,
            Status = 'Delivered',
            SerialNumber = 'VDD-TEST-001'
        );
        insert device;
    }

    @IsTest
    static void testGetTimelineData_DeliveredStatus() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400 Test' LIMIT 1];

        Test.startTest();
        List<VDD_TimelineCtrl.TimelineStage> stages = VDD_TimelineCtrl.getTimelineData(device.Id);
        Test.stopTest();

        System.assertEquals(5, stages.size(), 'Should return 5 timeline stages');
        System.assertEquals('Ordered', stages[0].stage);
        System.assertEquals('completed', stages[0].status);
        System.assertEquals('completed', stages[1].status); // Shipped
        System.assertEquals('current', stages[2].status); // Delivered
        System.assertEquals('upcoming', stages[3].status); // Installed
        System.assertEquals('upcoming', stages[4].status); // Operational
    }

    @IsTest
    static void testGetTimelineData_InstalledWithPing() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400 Test' LIMIT 1];
        device.Status = 'Installed';
        device.InstallDate = Date.today().addDays(-1);
        device.Last_Ping__c = Datetime.now();
        update device;

        Test.startTest();
        List<VDD_TimelineCtrl.TimelineStage> stages = VDD_TimelineCtrl.getTimelineData(device.Id);
        Test.stopTest();

        System.assertEquals(5, stages.size());
        System.assertEquals('current', stages[4].status, 'Operational should be current when installed + ping exists');
        System.assertEquals('completed', stages[3].status, 'Installed should be completed');
    }
}
