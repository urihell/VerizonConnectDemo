@isTest
private class VDD_SendOnboardingMessageTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Contact con = new Contact(FirstName = 'Jim', LastName = 'Stone', AccountId = acct.Id);
        insert con;
        Asset device = new Asset(Name = 'VDD-400-TEST', AccountId = acct.Id, Status = 'Installed', SerialNumber = 'VDD4-TEST');
        insert device;
    }

    @isTest
    static void testSendSuccess() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Stone' LIMIT 1];
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400-TEST' LIMIT 1];

        VDD_SendOnboardingMessage.Request req = new VDD_SendOnboardingMessage.Request();
        req.contactId = con.Id;
        req.assetId = device.Id;
        req.customerName = 'Jim';
        req.serialNumber = 'VDD4-TEST';
        req.vehicleName = 'Semi Truck #7';
        req.allMetrics = 'GPS: 2.3m ✓ | Signal: -72 dBm ✓ | Battery: 14.2V ✓';
        req.telemetryStatus = 'All Systems Go';

        Test.startTest();
        List<VDD_SendOnboardingMessage.Response> results = VDD_SendOnboardingMessage.send(
            new List<VDD_SendOnboardingMessage.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success);
        System.assertNotEquals(null, results[0].taskId);

        Task t = [SELECT Subject FROM Task WHERE Id = :results[0].taskId];
        System.assert(t.Subject.contains('Welcome to Verizon Connect'), 'Should be welcome message');
    }
}
