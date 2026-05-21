@isTest
private class VDD_DiagnoseAssetHealthTest {

    @isTest
    static void testDiagnoseNoAttributes() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Asset device = new Asset(Name = 'VDD-400-TEST', AccountId = acct.Id, Status = 'Installed');
        insert device;

        VDD_DiagnoseAssetHealth.Request req = new VDD_DiagnoseAssetHealth.Request();
        req.assetId = device.Id;
        req.thresholdName = 'VDD Battery Voltage Norm';

        Test.startTest();
        List<VDD_DiagnoseAssetHealth.Response> results = VDD_DiagnoseAssetHealth.diagnose(
            new List<VDD_DiagnoseAssetHealth.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success);
        System.assertNotEquals(null, results[0].diagnosis);
        System.assertNotEquals(null, results[0].severity);
    }
}
