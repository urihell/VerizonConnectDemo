@isTest
private class VDD_CollectInstallDatesTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Contact con = new Contact(FirstName = 'Jim', LastName = 'Stone', AccountId = acct.Id);
        insert con;
        Asset device = new Asset(Name = 'VDD-400-TEST', AccountId = acct.Id, Status = 'Delivered', SerialNumber = 'VDD4-TEST');
        insert device;
    }

    @isTest
    static void testCollectSuccess() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Stone' LIMIT 1];
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400-TEST' LIMIT 1];

        VDD_CollectInstallDates.Request req = new VDD_CollectInstallDates.Request();
        req.contactId = con.Id;
        req.assetId = device.Id;
        req.customerName = 'Jim';
        req.serialNumber = 'VDD4-TEST';

        Test.startTest();
        List<VDD_CollectInstallDates.Response> results = VDD_CollectInstallDates.collect(
            new List<VDD_CollectInstallDates.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success, 'Should succeed');
        System.assertNotEquals(null, results[0].taskId, 'Should create a Task');

        Task t = [SELECT Subject, Description FROM Task WHERE Id = :results[0].taskId];
        System.assert(t.Subject.contains('Install Date Request'), 'Task subject should reference install dates');
    }
}
