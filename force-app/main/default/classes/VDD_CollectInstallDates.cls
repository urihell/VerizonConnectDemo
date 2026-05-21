/**
 * Topic 1: Delivery Coordinator — Step 2
 * Collects 3 preferred installation date/time preferences from the customer.
 * Stores the preferences and creates a Task log + Chatter post for demo visibility.
 *
 * The Agentforce Service Agent extracts the 3 date preferences from the customer's
 * SMS reply and passes them as inputs to this function.
 */
public with sharing class VDD_CollectInstallDates {

    public class Request {
        @InvocableVariable(required=true description='Contact ID for the customer')
        public String contactId;
        @InvocableVariable(required=true description='Asset ID for the VDD device')
        public String assetId;
        @InvocableVariable(required=true description='Customer first name for personalization')
        public String customerName;
        @InvocableVariable(required=true description='Device serial number')
        public String serialNumber;
        @InvocableVariable(required=true description='First preferred install date (YYYY-MM-DD format)')
        public String preferredDate1;
        @InvocableVariable(required=true description='Time of day for first preference: Morning, Afternoon, or Evening')
        public String preferredTime1;
        @InvocableVariable(required=true description='Second preferred install date (YYYY-MM-DD format)')
        public String preferredDate2;
        @InvocableVariable(required=true description='Time of day for second preference: Morning, Afternoon, or Evening')
        public String preferredTime2;
        @InvocableVariable(required=true description='Third preferred install date (YYYY-MM-DD format)')
        public String preferredDate3;
        @InvocableVariable(required=true description='Time of day for third preference: Morning, Afternoon, or Evening')
        public String preferredTime3;
    }

    public class Response {
        @InvocableVariable public String taskId;
        @InvocableVariable public String confirmationMessage;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String preferredDate1;
        @InvocableVariable public String preferredTime1;
        @InvocableVariable public String preferredDate2;
        @InvocableVariable public String preferredTime2;
        @InvocableVariable public String preferredDate3;
        @InvocableVariable public String preferredTime3;
    }

    @InvocableMethod(label='Collect Install Date Preferences' description='Collects 3 preferred installation dates and times from the customer and logs the activity.')
    public static List<Response> collect(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // Format the preferences for display
                String pref1 = req.preferredDate1 + ' (' + req.preferredTime1 + ')';
                String pref2 = req.preferredDate2 + ' (' + req.preferredTime2 + ')';
                String pref3 = req.preferredDate3 + ' (' + req.preferredTime3 + ')';

                String preferenceSummary =
                    'CUSTOMER INSTALL DATE PREFERENCES:\n' +
                    '  1. ' + pref1 + '\n' +
                    '  2. ' + pref2 + '\n' +
                    '  3. ' + pref3;

                // 1. Create Task as activity log
                Task smsTask = new Task(
                    Subject = 'VDD SMS: Install Date Preferences Collected — ' + req.serialNumber,
                    WhoId = req.contactId,
                    WhatId = req.assetId,
                    Status = 'Completed',
                    Priority = 'High',
                    TaskSubtype = 'Call',
                    Description = 'INSTALL DATE PREFERENCES COLLECTED FROM: ' + req.customerName + '\n' +
                        'CHANNEL: Verizon Connect SMS (+1-201-908-6942)\n' +
                        '─────────────────────────────────\n' +
                        preferenceSummary + '\n\n' +
                        'Device: VDD-400 (SN: ' + req.serialNumber + ')\n' +
                        'These preferences will be applied to the installer work order and service appointment.'
                );
                insert smsTask;

                // 2. Post to Asset Chatter feed for demo visibility
                FeedItem post = new FeedItem(
                    ParentId = req.assetId,
                    Body = '📱 VDD Install date preferences collected from ' + req.customerName + ' for device ' + req.serialNumber + ':\n\n' +
                        '  1️⃣ ' + pref1 + '\n' +
                        '  2️⃣ ' + pref2 + '\n' +
                        '  3️⃣ ' + pref3 + '\n\n' +
                        'Channel: Verizon Connect SMS • Preferences logged ✓'
                );
                insert post;

                // Pass through preferences for downstream use by Create Installer Work Order
                res.preferredDate1 = req.preferredDate1;
                res.preferredTime1 = req.preferredTime1;
                res.preferredDate2 = req.preferredDate2;
                res.preferredTime2 = req.preferredTime2;
                res.preferredDate3 = req.preferredDate3;
                res.preferredTime3 = req.preferredTime3;

                res.taskId = smsTask.Id;
                res.confirmationMessage = 'Install date preferences collected from ' + req.customerName + ': ' +
                    pref1 + ', ' + pref2 + ', ' + pref3 + '. ' +
                    'Activity logged on device ' + req.serialNumber + '. Ready to create installer work order.';
                res.success = true;

            } catch (Exception e) {
                res.success = false;
                res.confirmationMessage = 'Error collecting install date preferences: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
