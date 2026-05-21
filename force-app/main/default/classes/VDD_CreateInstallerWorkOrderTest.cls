@isTest
private class VDD_CreateInstallerWorkOrderTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Asset device = new Asset(Name = 'VDD-400-TEST', AccountId = acct.Id, Status = 'Delivered', SerialNumber = 'VDD4-TEST');
        insert device;
    }

    @isTest
    static void testCreateSuccess() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Fleet Co' LIMIT 1];
        Asset device = [SELECT Id FROM Asset WHERE Name = 'VDD-400-TEST' LIMIT 1];

        VDD_CreateInstallerWorkOrder.Request req = new VDD_CreateInstallerWorkOrder.Request();
        req.assetId = device.Id;
        req.accountId = acct.Id;
        req.serialNumber = 'VDD4-TEST';
        req.deviceESN = 'ESN12345';
        req.vehicleName = 'Semi Truck #7';
        req.customerName = 'Jim Stone';
        req.customerPhone = '555-0199';
        req.deliveryAddress = 'Fleet Yard, Old Bridge NJ';

        Test.startTest();
        List<VDD_CreateInstallerWorkOrder.Response> results = VDD_CreateInstallerWorkOrder.create(
            new List<VDD_CreateInstallerWorkOrder.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success, 'Should succeed');
        System.assertNotEquals(null, results[0].workOrderNumber, 'Should have WO number');

        WorkOrder wo = [SELECT Subject, Priority FROM WorkOrder WHERE Id = :results[0].workOrderId];
        System.assert(wo.Subject.contains('VDD-400 Install'), 'WO subject should reference VDD install');
        System.assertEquals('High', wo.Priority);
    }
}
