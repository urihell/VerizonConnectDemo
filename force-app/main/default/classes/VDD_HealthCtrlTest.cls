@IsTest
private class VDD_HealthCtrlTest {

    @TestSetup
    static void setupData() {
        Account acct = new Account(Name = 'Test Paving Co');
        insert acct;

        Asset device = new Asset(
            Name = 'VDD-400 Test',
            AccountId = acct.Id,
            Status = 'Installed',
            SerialNumber = 'VDD-TEST-001',
            Device_ESN__c = 'ESN-TEST-001',
            Last_Ping__c = Datetime.now()
        );
        insert device;
    }

    @IsTest
    static void testGetHealthMetrics() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400 Test' LIMIT 1];

        Test.startTest();
        Map<String, String> metrics = VDD_HealthCtrl.getHealthMetrics(device.Id);
        Test.stopTest();

        // In test context, no AssetAttribute records exist unless created via API
        // This verifies the method runs without errors
        System.assertNotEquals(null, metrics, 'Metrics map should not be null');
    }

    @IsTest
    static void testGetThresholdStatus() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400 Test' LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> monitors = VDD_HealthCtrl.getThresholdStatus(device.Id);
        Test.stopTest();

        System.assertNotEquals(null, monitors, 'Monitors list should not be null');
    }

    @IsTest
    static void testGetAssetInfo() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400 Test' LIMIT 1];

        Test.startTest();
        Map<String, Object> info = VDD_HealthCtrl.getAssetInfo(device.Id);
        Test.stopTest();

        System.assertEquals('VDD-400 Test', info.get('name'));
        System.assertEquals('Installed', info.get('status'));
        System.assertEquals('VDD-TEST-001', info.get('serialNumber'));
        System.assertEquals('ESN-TEST-001', info.get('deviceESN'));
    }
}
