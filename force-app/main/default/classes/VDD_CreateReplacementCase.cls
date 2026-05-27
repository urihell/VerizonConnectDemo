/**
 * Topic 3: Proactive Health Monitor
 * Creates a proactive replacement case and notifies the customer about the detected issue.
 */
public with sharing class VDD_CreateReplacementCase {

    public class Request {
        @InvocableVariable(required=true description='The Asset ID with the issue')
        public String assetId;
        @InvocableVariable(required=true description='Account ID')
        public String accountId;
        @InvocableVariable(required=true description='Contact ID for the customer')
        public String contactId;
        @InvocableVariable(required=true description='Diagnostic summary')
        public String diagnosis;
        @InvocableVariable(required=true description='Severity: Critical or Warning')
        public String severity;
        @InvocableVariable(required=true description='Recommended action')
        public String recommendedAction;
        @InvocableVariable(required=true description='Vehicle name')
        public String vehicleName;
        @InvocableVariable(required=true description='Customer name')
        public String customerName;
    }

    public class Response {
        @InvocableVariable public String caseNumber;
        @InvocableVariable public String caseId;
        @InvocableVariable public String confirmationMessage;
        @InvocableVariable public Boolean success;
    }

    @InvocableMethod(label='Create Replacement Case' description='Creates a proactive replacement case and notifies the customer about the detected issue.')
    public static List<Response> create(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // Create proactive Case
                Case c = new Case(
                    Subject = 'Proactive Alert: ' + req.severity + ' — ' + req.vehicleName,
                    AccountId = req.accountId,
                    ContactId = req.contactId,
                    AssetId = req.assetId,
                    Priority = req.severity == 'Critical' ? 'High' : 'Medium',
                    Status = 'New',
                    Origin = 'Agentforce',
                    Description = 'PROACTIVE HEALTH ALERT\n' +
                        '========================\n\n' +
                        'Vehicle: ' + req.vehicleName + '\n' +
                        'Severity: ' + req.severity + '\n\n' +
                        'DIAGNOSIS:\n' + req.diagnosis + '\n\n' +
                        'RECOMMENDED ACTION:\n' + req.recommendedAction + '\n\n' +
                        'This case was automatically created by Verizon Connect Agentforce ' +
                        'upon detecting a threshold breach. Our team is proactively addressing ' +
                        'this before it impacts fleet operations.'
                );
                insert c;

                // Re-query for case number
                c = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id LIMIT 1];

                // Create notification Task
                Task notification = new Task(
                    Subject = 'SMS: Proactive Alert — ' + req.vehicleName,
                    WhoId = req.contactId,
                    WhatId = c.Id,
                    Status = 'Completed',
                    Priority = 'High',
                    Description = 'Hi ' + req.customerName + ',\n\n' +
                        'Our monitoring system detected an issue with the tracking device on ' +
                        req.vehicleName + '.\n\n' +
                        'Severity: ' + req.severity + '\n' +
                        'Case #: ' + c.CaseNumber + '\n\n' +
                        'Our team is already working on it — no action needed from you.\n' +
                        'We\'ll keep you updated on the resolution.\n\n' +
                        '— Verizon Connect Fleet Support'
                );
                insert notification;

                res.caseId = c.Id;
                res.caseNumber = c.CaseNumber;
                res.confirmationMessage = 'Case ' + c.CaseNumber + ' created (' + req.severity + '). Customer ' + req.customerName + ' notified. Recommended: ' + req.recommendedAction;
                res.success = true;

            } catch (Exception e) {
                res.success = false;
                res.confirmationMessage = 'Error creating replacement case: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}