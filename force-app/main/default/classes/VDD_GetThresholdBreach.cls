/**
 * Topic 3: Proactive Health Monitor
 * Reads RecordsetFltrCritMonitor to identify which threshold was breached and the affected asset.
 */
public with sharing class VDD_GetThresholdBreach {

    public class Request {
        @InvocableVariable(required=true description='The Asset ID that triggered the threshold breach')
        public String assetId;
    }

    public class Response {
        @InvocableVariable public String assetName;
        @InvocableVariable public String thresholdName;
        @InvocableVariable public String accountName;
        @InvocableVariable public String accountId;
        @InvocableVariable public String customerName;
        @InvocableVariable public String customerPhone;
        @InvocableVariable public String contactId;
        @InvocableVariable public String vehicleName;
        @InvocableVariable public String serialNumber;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Get Threshold Breach Details' description='Reads the threshold monitor to identify which criteria was breached and the affected asset.')
    public static List<Response> getBreach(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Asset device = [
                    SELECT Id, Name, SerialNumber, Account.Id, Account.Name, Parent.Name
                    FROM Asset
                    WHERE Id = :req.assetId
                    LIMIT 1
                ];

                res.assetName = device.Name;
                res.serialNumber = device.SerialNumber;
                res.accountName = device.Account?.Name;
                res.accountId = device.Account?.Id;
                res.vehicleName = device.Parent?.Name;

                // Get breached threshold monitors
                List<RecordsetFltrCritMonitor> monitors = [
                    SELECT Name, IsWithinThreshold, RecordsetFilterCriteria.Name
                    FROM RecordsetFltrCritMonitor
                    WHERE AssetId = :req.assetId
                    AND IsWithinThreshold = false
                ];

                if (!monitors.isEmpty()) {
                    res.thresholdName = monitors[0].RecordsetFilterCriteria.Name;
                } else {
                    res.thresholdName = 'Unknown Threshold';
                }

                // Get contact
                List<Contact> contacts = [
                    SELECT Id, Name, Phone
                    FROM Contact
                    WHERE AccountId = :device.AccountId
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
                if (!contacts.isEmpty()) {
                    res.contactId = contacts[0].Id;
                    res.customerName = contacts[0].Name;
                    res.customerPhone = contacts[0].Phone;
                }

                res.success = true;
                res.message = 'Threshold breach: ' + res.thresholdName + ' on ' + device.Name;

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error getting breach details: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}