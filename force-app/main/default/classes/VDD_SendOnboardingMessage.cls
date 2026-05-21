/**
 * Topic 2: Post-Install Onboarding
 * Creates a Task simulating welcome SMS with telemetry status and dashboard access link.
 */
public with sharing class VDD_SendOnboardingMessage {

    public class Request {
        @InvocableVariable(required=true description='Contact ID for the customer')
        public String contactId;
        @InvocableVariable(required=true description='Asset ID for the VDD device')
        public String assetId;
        @InvocableVariable(required=true description='Customer name')
        public String customerName;
        @InvocableVariable(required=true description='Device serial number')
        public String serialNumber;
        @InvocableVariable(required=true description='Vehicle name')
        public String vehicleName;
        @InvocableVariable(required=true description='All telemetry metrics summary')
        public String allMetrics;
        @InvocableVariable(required=true description='Telemetry status: All Systems Go or Issues Detected')
        public String telemetryStatus;
    }

    public class Response {
        @InvocableVariable public String taskId;
        @InvocableVariable public String confirmationMessage;
        @InvocableVariable public Boolean success;
    }

    @InvocableMethod(label='Send Onboarding Message' description='Sends a welcome message to the customer with telemetry status and dashboard access.')
    public static List<Response> send(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Task smsTask = new Task(
                    Subject = 'SMS: Welcome to Verizon Connect Fleet — ' + req.serialNumber,
                    WhoId = req.contactId,
                    WhatId = req.assetId,
                    Status = 'Completed',
                    Priority = 'Normal',
                    Description = 'Hi ' + req.customerName + ',\n\n' +
                        'Great news! Your VDD-400 GPS Tracking Unit (SN: ' + req.serialNumber + ') ' +
                        'is installed and reporting on ' + req.vehicleName + '!\n\n' +
                        'Telemetry Status: ' + req.telemetryStatus + '\n' +
                        req.allMetrics + '\n\n' +
                        'Access your fleet dashboard at connect.verizon.com/fleet\n' +
                        'Your dedicated support line: 1-800-VZW-FLEET\n\n' +
                        'Welcome to Verizon Connect!\n' +
                        '— Your Fleet Team'
                );
                insert smsTask;

                res.taskId = smsTask.Id;
                res.confirmationMessage = 'Welcome message sent to ' + req.customerName + '. Telemetry: ' + req.telemetryStatus;
                res.success = true;

            } catch (Exception e) {
                res.success = false;
                res.confirmationMessage = 'Error sending onboarding message: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
