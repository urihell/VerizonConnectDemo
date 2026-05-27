/**
 * Topic 1: Delivery Coordinator — Step 3
 * Updates the auto-created Work Order (from VDD_CreateDeliveryWorkOrder) with
 * the 3 customer date/time preferences collected by the Agentforce SMS agent,
 * and updates the auto-created Service Appointment with scheduling details.
 *
 * Finds the existing WO via ProductRequest.WorkOrderId (standard field).
 * If no existing Work Order is found (edge case), falls back to creating a new one.
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

    @InvocableMethod(label='Create Installer Work Order' description='Updates the existing delivery Work Order with customer date/time preferences and updates the auto-created Service Appointment for the 3rd-party installer.')
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

                WorkOrder wo;
                Boolean updatedExisting = false;

                // 1. Find existing WO via ProductRequest.WorkOrderId (standard field)
                //    The WO was auto-created by VDD_CreateDeliveryWorkOrder and linked
                //    to the ProductRequest via pr.WorkOrderId = wo.Id
                List<ProductRequest> prs = [
                    SELECT Id, WorkOrderId
                    FROM ProductRequest
                    WHERE AccountId = :req.accountId
                      AND WorkOrderId != null
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!prs.isEmpty()) {
                    // Found an existing WO — UPDATE it with preferred dates
                    wo = [
                        SELECT Id, WorkOrderNumber, Subject, Description
                        FROM WorkOrder
                        WHERE Id = :prs[0].WorkOrderId
                        LIMIT 1
                    ];

                    wo.Preferred_Date_1__c = date1;
                    wo.Preferred_Time_1__c = req.preferredTime1;
                    wo.Preferred_Date_2__c = date2;
                    wo.Preferred_Time_2__c = req.preferredTime2;
                    wo.Preferred_Date_3__c = date3;
                    wo.Preferred_Time_3__c = req.preferredTime3;
                    wo.Priority = 'High';

                    // Append date preferences to the existing description
                    String dateSection = '\n\nCUSTOMER PREFERRED INSTALL DATES:\n' +
                        '  1. ' + req.preferredDate1 + ' (' + req.preferredTime1 + ')\n' +
                        '  2. ' + req.preferredDate2 + ' (' + req.preferredTime2 + ')\n' +
                        '  3. ' + req.preferredDate3 + ' (' + req.preferredTime3 + ')';

                    if (wo.Description != null && !wo.Description.contains('CUSTOMER PREFERRED INSTALL DATES')) {
                        // Replace the placeholder note with actual dates
                        wo.Description = wo.Description.replace(
                            '\nNote: Customer preferred installation dates will be added once confirmed by the Delivery Coordination agent.',
                            dateSection
                        );
                        // If the replace didn't match (different format), just append
                        if (!wo.Description.contains('CUSTOMER PREFERRED INSTALL DATES')) {
                            wo.Description += dateSection;
                        }
                    } else if (wo.Description != null) {
                        // Dates already present — leave description as-is to avoid duplicates
                    } else {
                        wo.Description = dateSection;
                    }

                    update wo;
                    updatedExisting = true;

                    // 2. Find and UPDATE the auto-created Service Appointment
                    //    (auto-created by the Installation WorkType's ShouldAutoCreateSvcAppt flag)
                    Datetime saStart = getAppointmentStart(date1, req.preferredTime1);
                    Datetime saEnd = saStart.addHours(2);

                    List<ServiceAppointment> existingSAs = [
                        SELECT Id, Subject, Status
                        FROM ServiceAppointment
                        WHERE ParentRecordId = :wo.Id
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];

                    ServiceAppointment sa;
                    if (!existingSAs.isEmpty()) {
                        // Update existing auto-created SA
                        sa = existingSAs[0];
                        sa.EarliestStartTime = saStart;
                        sa.DueDate = saEnd.addDays(7);
                        sa.Preferred_Date_1__c = date1;
                        sa.Preferred_Time_1__c = req.preferredTime1;
                        sa.Preferred_Date_2__c = date2;
                        sa.Preferred_Time_2__c = req.preferredTime2;
                        sa.Preferred_Date_3__c = date3;
                        sa.Preferred_Time_3__c = req.preferredTime3;
                        sa.Description = 'Install VDD-400 GPS Tracking Units — ' + req.customerName + '\n' +
                            'Phone: ' + req.customerPhone + '\n' +
                            'Location: ' + req.deliveryAddress + '\n\n' +
                            'Customer preferred dates:\n' +
                            '  1. ' + req.preferredDate1 + ' (' + req.preferredTime1 + ')\n' +
                            '  2. ' + req.preferredDate2 + ' (' + req.preferredTime2 + ')\n' +
                            '  3. ' + req.preferredDate3 + ' (' + req.preferredTime3 + ')';
                        update sa;
                    } else {
                        // No auto-created SA found — create one
                        sa = new ServiceAppointment(
                            ParentRecordId = wo.Id,
                            Subject = 'VDD-400 Fleet Installation — ' + req.customerName,
                            Status = 'None',
                            EarliestStartTime = saStart,
                            DueDate = saEnd.addDays(7),
                            Preferred_Date_1__c = date1,
                            Preferred_Time_1__c = req.preferredTime1,
                            Preferred_Date_2__c = date2,
                            Preferred_Time_2__c = req.preferredTime2,
                            Preferred_Date_3__c = date3,
                            Preferred_Time_3__c = req.preferredTime3,
                            Description = 'Install VDD-400 GPS Tracking Units — ' + req.customerName + '\n' +
                                'Phone: ' + req.customerPhone + '\n' +
                                'Location: ' + req.deliveryAddress + '\n\n' +
                                'Customer preferred dates:\n' +
                                '  1. ' + req.preferredDate1 + ' (' + req.preferredTime1 + ')\n' +
                                '  2. ' + req.preferredDate2 + ' (' + req.preferredTime2 + ')\n' +
                                '  3. ' + req.preferredDate3 + ' (' + req.preferredTime3 + ')'
                        );
                        insert sa;
                    }

                    res.serviceAppointmentId = sa.Id;

                } else {
                    // FALLBACK: No ProductRequest with WO found — create a new Work Order
                    List<WorkType> workTypes = [
                        SELECT Id FROM WorkType WHERE Name = 'Installation' LIMIT 1
                    ];
                    Id installationWorkTypeId = workTypes.isEmpty() ? null : workTypes[0].Id;

                    wo = new WorkOrder(
                        Subject = 'VDD-400 Install — ' + req.customerName + ' ' + req.vehicleName,
                        AccountId = req.accountId,
                        AssetId = req.assetId,
                        WorkTypeId = installationWorkTypeId,
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

                    // Fallback SA creation — WorkType auto-create may handle this,
                    // but create manually if none found after a brief re-query
                    Datetime saStart = getAppointmentStart(date1, req.preferredTime1);
                    Datetime saEnd = saStart.addHours(2);

                    List<ServiceAppointment> autoSAs = [
                        SELECT Id FROM ServiceAppointment
                        WHERE ParentRecordId = :wo.Id LIMIT 1
                    ];

                    ServiceAppointment sa;
                    if (!autoSAs.isEmpty()) {
                        sa = autoSAs[0];
                        sa.EarliestStartTime = saStart;
                        sa.DueDate = saEnd.addDays(7);
                        sa.Preferred_Date_1__c = date1;
                        sa.Preferred_Time_1__c = req.preferredTime1;
                        sa.Preferred_Date_2__c = date2;
                        sa.Preferred_Time_2__c = req.preferredTime2;
                        sa.Preferred_Date_3__c = date3;
                        sa.Preferred_Time_3__c = req.preferredTime3;
                        update sa;
                    } else {
                        sa = new ServiceAppointment(
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
                                'Location: ' + req.deliveryAddress
                        );
                        insert sa;
                    }

                    res.serviceAppointmentId = sa.Id;
                }

                // Re-query to get the WorkOrderNumber
                wo = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id = :wo.Id LIMIT 1];

                res.workOrderId = wo.Id;
                res.workOrderNumber = wo.WorkOrderNumber;
                String territoryName = territories.isEmpty() ? 'Unassigned' : '*New Jersey';
                String action = updatedExisting ? 'updated' : 'created';
                res.confirmationMessage = 'Work Order ' + wo.WorkOrderNumber + ' ' + action + ' for fleet installation. ' +
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
     * Parse a date string in YYYY-MM-DD format. Returns today+3 if parse fails.
     */
    private static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr)) return Date.today().addDays(3);
        try {
            return Date.valueOf(dateStr);
        } catch (Exception e) {
            try {
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
