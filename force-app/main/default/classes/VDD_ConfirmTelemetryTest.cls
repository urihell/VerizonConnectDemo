@isTest
private class VDD_ConfirmTelemetryTest {

    @isTest
    static void testConfirmWithNoAttributes() {
        Account acct = new Account(Name = 'Test Fleet Co');
        insert acct;
        Asset device = new Asset(Name = 'VDD-400-TEST', AccountId = acct.Id, Status = 'Installed');
        insert device;

        VDD_ConfirmTelemetry.Request req = new VDD_ConfirmTelemetry.Request();
        req.assetId = device.Id;

        Test.startTest();
        List<VDD_ConfirmTelemetry.Response> results = VDD_ConfirmTelemetry.confirm(
            new List<VDD_ConfirmTelemetry.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success);
        // With no attributes, telemetry status should still return
        System.assertNotEquals(null, results[0].telemetryStatus);
    }
}
