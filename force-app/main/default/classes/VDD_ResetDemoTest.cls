@isTest
private class VDD_ResetDemoTest {
    @isTest
    static void testExecuteReturnsResponse() {
        // VDD_ResetDemo relies on hardcoded IDs from the demo org.
        // This test validates the invocable shape and exception handling.
        List<VDD_ResetDemo.Response> results = VDD_ResetDemo.execute(new List<SObject>());
        System.assertNotEquals(null, results, 'Should return a response list');
        System.assertEquals(1, results.size(), 'Should return exactly one response');
        // In a test context without the demo data, we expect the reset to fail gracefully
        System.assertNotEquals(null, results[0].message, 'Response should have a message');
    }
}
