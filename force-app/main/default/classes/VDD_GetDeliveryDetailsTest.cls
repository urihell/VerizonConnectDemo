@isTest
private class VDD_GetDeliveryDetailsTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Driver', AccountId = acct.Id, Phone = '555-0199', Email = 'test@fleet.demo');
        insert con;
        Asset vehicle = new Asset(Name = 'Test Truck #1', AccountId = acct.Id, Status = 'Installed');
        insert vehicle;
        Asset device = new Asset(
            Name = 'VDD-400-TEST-001',
            AccountId = acct.Id,
            ParentId = vehicle.Id,
            Status = 'Delivered',
            SerialNumber = 'VDD4-TEST-001',
            Device_ESN__c = 'ESN12345'
        );
        insert device;
    }

    @isTest
    static void testGetDetailsSuccess() {
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400-TEST-001' LIMIT 1];
        VDD_GetDeliveryDetails.Request req = new VDD_GetDeliveryDetails.Request();
        req.assetId = device.Id;

        Test.startTest();
        List<VDD_GetDeliveryDetails.Response> results = VDD_GetDeliveryDetails.getDetails(
            new List<VDD_GetDeliveryDetails.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success, 'Should succeed');
        System.assertEquals('VDD-400-TEST-001', results[0].assetName);
        System.assertEquals('VDD4-TEST-001', results[0].serialNumber);
        System.assertEquals('ESN12345', results[0].deviceESN);
        System.assertEquals('Test Fleet Co', results[0].accountName);
        System.assertEquals('Test Driver', results[0].customerName);
    }

    @isTest
    static void testGetDetailsInvalidId() {
        VDD_GetDeliveryDetails.Request req = new VDD_GetDeliveryDetails.Request();
        req.assetId = '02iaj000000000000A'; // fake ID

        Test.startTest();
        List<VDD_GetDeliveryDetails.Response> results = VDD_GetDeliveryDetails.getDetails(
            new List<VDD_GetDeliveryDetails.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(!results[0].success, 'Should fail for invalid ID');
    }
}
