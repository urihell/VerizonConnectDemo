@isTest
private class VDD_GetInstallStatusTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Contact con = new Contact(FirstName = 'Jim', LastName = 'Stone', AccountId = acct.Id, Phone = '555-0199', Email = 'jim@fleet.demo');
        insert con;
        Asset vehicle = new Asset(Name = 'Test Truck #1', AccountId = acct.Id, Status = 'Installed');
        insert vehicle;
        Asset device = new Asset(
            Name = 'VDD-400-TEST',
            AccountId = acct.Id,
            ParentId = vehicle.Id,
            Status = 'Installed',
            SerialNumber = 'VDD4-TEST',
            InstallDate = Date.today()
        );
        insert device;
    }

    @isTest
    static void testGetStatusInstalled() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400-TEST' LIMIT 1];
        VDD_GetInstallStatus.Request req = new VDD_GetInstallStatus.Request();
        req.assetId = device.Id;

        Test.startTest();
        List<VDD_GetInstallStatus.Response> results = VDD_GetInstallStatus.getStatus(
            new List<VDD_GetInstallStatus.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success);
        System.assert(results[0].isInstalled, 'Should be installed');
        System.assertEquals('VDD-400-TEST', results[0].assetName);
        System.assertEquals('Test Truck #1', results[0].vehicleName);
        System.assertEquals('Jim Stone', results[0].customerName);
    }
}
