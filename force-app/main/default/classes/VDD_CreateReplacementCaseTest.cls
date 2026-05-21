@isTest
private class VDD_CreateReplacementCaseTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Contact con = new Contact(FirstName = 'Jim', LastName = 'Stone', AccountId = acct.Id);
        insert con;
        Asset device = new Asset(Name = 'VDD-400-TEST', AccountId = acct.Id, Status = 'Installed');
        insert device;
    }

    @isTest
    static void testCreateCaseSuccess() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Fleet Co' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Stone' LIMIT 1];
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400-TEST' LIMIT 1];

        VDD_CreateReplacementCase.Request req = new VDD_CreateReplacementCase.Request();
        req.assetId = device.Id;
        req.accountId = acct.Id;
        req.contactId = con.Id;
        req.diagnosis = 'Battery voltage critically low at 11.4V';
        req.severity = 'Critical';
        req.recommendedAction = 'Replace vehicle battery';
        req.vehicleName = 'Semi Truck #7';
        req.customerName = 'Jim Stone';

        Test.startTest();
        List<VDD_CreateReplacementCase.Response> results = VDD_CreateReplacementCase.create(
            new List<VDD_CreateReplacementCase.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success);
        System.assertNotEquals(null, results[0].caseNumber);

        Case c = [SELECT Subject, Priority, Origin FROM Case WHERE Id = :results[0].caseId];
        System.assert(c.Subject.contains('Proactive Alert'));
        System.assertEquals('High', c.Priority);
        System.assertEquals('Agentforce', c.Origin);

        // Verify notification task was created
        List<Task> tasks = [SELECT Subject FROM Task WHERE WhatId = :results[0].caseId];
        System.assertEquals(1, tasks.size());
        System.assert(tasks[0].Subject.contains('Proactive Alert'));
    }
}
