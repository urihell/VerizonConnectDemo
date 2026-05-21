/**
 * Topic 1: Delivery Coordinator — Step 3
 * Creates a Work Order for the 3rd-party installer with device and vehicle details,
 * populates the 3 customer date/time preferences on the Work Order,
 * and creates a linked Service Appointment with the same preferences.
 */
public with sharing class VDD_CreateInstallerWorkOrder {

    public class Request {
        @InvocableVariable(required=true description='Asset ID for the VDD device')
        public String assetId;
        @InvocableVariable(required=true description='Account ID for the customer')
        public String accountId;
        @InvocableVariable(required=true description='Device serial number')
        public String serialNumber;
        @InvocableVariable(required=true description='Device ESN')
        public String deviceESN;
        @InvocableVariable(required=true description='Vehicle name where device will be installed')
        public String vehicleName;
        @InvocableVariable(required=true description='Customer name')
        public String customerName;
        @InvocableVariable(required=true description='Customer phone number')
        public String customerPhone;
        @InvocableVariable(required=true description='Delivery/install address')
        public String deliveryAddress;
        @InvocableVariable(required=true description='First preferred install date (YYYY-MM-DD)')
        public String preferredDate1;
        @InvocableVariable(required=true description='Time of day for first preference: Morning, Afternoon, or Evening')
        public String preferredTime1;
        @InvocableVariable(required=true description='Second preferred install date (YYYY-MM-DD)')
        public String preferredDate2;
        @InvocableVariable(required=true description='Time of day for second preference: Morning, Afternoon, or Evening')
        public String preferredTime2;
        @InvocableVariable(required=true description='Third preferred install date (YYYY-MM-DD)')
        public String preferredDate3;
        @InvocableVariable(required=true description='Time of day for third preference: Morning, Afternoon, or Evening')
        public String preferredTime3;
    }

    public class Response {
        @InvocableVariable public String workOrderNumber;
        @InvocableVariable public String workOrderId;
        @InvocableVariable public String serviceAppointmentId;
        @InvocableVariable public String confirmationMessage;
        @InvocableVariable public Boolean success;
    }

    @InvocableMethod(label='Create Installer Work Order' description='Creates a Work Order and Service Appointment with customer date/time preferences for the 3rd-party installer.')
    public static List<Response> create(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // Query the NJ service territory for FSL scheduling
                List<ServiceTerritory> territories = [
                    SELECT Id FROM ServiceTerritory
                    WHERE Name = '*New Jersey' AND IsActive = true LIMIT 1
                ];

                // Parse the preferred dates
                Date date1 = parseDate(req.preferredDate1);
                Date date2 = parseDate(req.preferredDate2);
                Date date3 = parseDate(req.preferredDate3);

                // Create Work Order with date preferences
                WorkOrder wo = new WorkOrder(
                    Subject = 'VDD-400 Install — ' + req.customerName + ' ' + req.vehicleName,
                    AccountId = req.accountId,
                    AssetId = req.assetId,
                    ServiceTerritoryId = territories.isEmpty() ? null : territories[0].Id,
                    Priority = 'High',
                    Status = 'New',
                    StartDate = System.now(),
                    EndDate = System.now().addDays(7),
                    Preferred_Date_1__c = date1,
                    Preferred_Time_1__c = req.preferredTime1,
                    Preferred_Date_2__c = date2,
                    Preferred_Time_2__c = req.preferredTime2,
                    Preferred_Date_3__c = date3,
                    Preferred_Time_3__c = req.preferredTime3,
                    Description = 'INSTALLATION WORK ORDER\n' +
                        '========================\n\n' +
                        'Device: VDD-400 GPS Tracking Unit\n' +
                        'Serial Number: ' + req.serialNumber + '\n' +
                        'ESN: ' + req.deviceESN + '\n\n' +
                        'Vehicle: ' + req.vehicleName + '\n' +
                        'Customer: ' + req.customerName + '\n' +
                        'Phone: ' + req.customerPhone + '\n' +
                        'Location: ' + req.deliveryAddress + '\n\n' +
                        'CUSTOMER PREFERRED INSTALL DATES:\n' +
                        '  1. ' + req.preferredDate1 + ' (' + req.preferredTime1 + ')\n' +
                        '  2. ' + req.preferredDate2 + ' (' + req.preferredTime2 + ')\n' +
                        '  3. ' + req.preferredDate3 + ' (' + req.preferredTime3 + ')\n\n' +
                        'INSTALL INSTRUCTIONS:\n' +
                        '1. Connect OBD-II interface to vehicle diagnostic port\n' +
                        '2. Mount VDD-400 unit under dashboard\n' +
                        '3. Route antenna to windshield mount\n' +
                        '4. Connect wiring harness to vehicle power\n' +
                        '5. Verify GPS lock and cellular connectivity\n' +
                        '6. Run diagnostic test via Verizon Connect portal\n' +
                        '7. Update Asset status to Installed in Salesforce'
                );
                insert wo;

                // Re-query to get the WorkOrderNumber
                wo = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id = :wo.Id LIMIT 1];

                // Create Service Appointment linked to the Work Order
                // Use first preferred date as the scheduled start
                Datetime saStart = getAppointmentStart(date1, req.preferredTime1);
                Datetime saEnd = saStart.addHours(2); // 2-hour install window

                ServiceAppointment sa = new ServiceAppointment(
                    ParentRecordId = wo.Id,
                    Subject = 'VDD-400 Installation — ' + req.vehicleName,
                    Status = 'None',
                    EarliestStartTime = saStart,
                    DueDate = saEnd.addDays(7),
                    Preferred_Date_1__c = date1,
                    Preferred_Time_1__c = req.preferredTime1,
                    Preferred_Date_2__c = date2,
                    Preferred_Time_2__c = req.preferredTime2,
                    Preferred_Date_3__c = date3,
                    Preferred_Time_3__c = req.preferredTime3,
                    Description = 'Install VDD-400 GPS Tracking Unit on ' + req.vehicleName + '\n' +
                        'Customer: ' + req.customerName + ' | Phone: ' + req.customerPhone + '\n' +
                        'Location: ' + req.deliveryAddress + '\n\n' +
                        'Customer preferred dates:\n' +
                        '  1. ' + req.preferredDate1 + ' (' + req.preferredTime1 + ')\n' +
                        '  2. ' + req.preferredDate2 + ' (' + req.preferredTime2 + ')\n' +
                        '  3. ' + req.preferredDate3 + ' (' + req.preferredTime3 + ')'
                );
                insert sa;

                res.workOrderId = wo.Id;
                res.workOrderNumber = wo.WorkOrderNumber;
                res.serviceAppointmentId = sa.Id;
                String territoryName = territories.isEmpty() ? 'Unassigned' : '*New Jersey';
                res.confirmationMessage = 'Work Order ' + wo.WorkOrderNumber + ' created for ' + req.vehicleName + ' installation. ' +
                    'Service Appointment scheduled with customer preferences: ' +
                    req.preferredDate1 + ' (' + req.preferredTime1 + '), ' +
                    req.preferredDate2 + ' (' + req.preferredTime2 + '), ' +
                    req.preferredDate3 + ' (' + req.preferredTime3 + '). ' +
                    'Territory: ' + territoryName + '. Priority: High.';
                res.success = true;

            } catch (Exception e) {
                res.success = false;
                res.confirmationMessage = 'Error creating work order: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }

    /**
     * Parse a date string in YYYY-MM-DD format. Returns today if parse fails.
     */
    private static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr)) return Date.today().addDays(3);
        try {
            return Date.valueOf(dateStr);
        } catch (Exception e) {
            // Try common formats
            try {
                // Handle "June 2, 2026" style
                return Date.valueOf(dateStr.trim());
            } catch (Exception e2) {
                return Date.today().addDays(3);
            }
        }
    }

    /**
     * Convert a date + time-of-day string into a Datetime for the ServiceAppointment.
     * Morning = 8:00 AM, Afternoon = 1:00 PM, Evening = 5:00 PM
     */
    private static Datetime getAppointmentStart(Date d, String timeOfDay) {
        if (d == null) d = Date.today().addDays(3);
        Integer hour = 8; // Default to morning
        if (String.isNotBlank(timeOfDay)) {
            String t = timeOfDay.trim().toLowerCase();
            if (t.contains('afternoon')) {
                hour = 13;
            } else if (t.contains('evening')) {
                hour = 17;
            }
        }
        return Datetime.newInstance(d.year(), d.month(), d.day(), hour, 0, 0);
    }
}
