/**
 * Topic 2: Post-Install Onboarding
 * Reads Asset and parent vehicle info after installation is complete.
 */
public with sharing class VDD_GetInstallStatus {

    public class Request {
        @InvocableVariable(required=true description='The Asset ID for the installed VDD device')
        public String assetId;
    }

    public class Response {
        @InvocableVariable public String assetName;
        @InvocableVariable public String serialNumber;
        @InvocableVariable public String vehicleName;
        @InvocableVariable public String installDate;
        @InvocableVariable public String customerName;
        @InvocableVariable public String customerEmail;
        @InvocableVariable public String customerPhone;
        @InvocableVariable public String contactId;
        @InvocableVariable public String assetStatus;
        @InvocableVariable public Boolean isInstalled;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Get VDD Install Status' description='Retrieves installation status and details for a VDD device.')
    public static List<Response> getStatus(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Asset device = [
                    SELECT Id, Name, SerialNumber, Status, InstallDate,
                           Account.Name, Parent.Name
                    FROM Asset
                    WHERE Id = :req.assetId
                    LIMIT 1
                ];

                res.assetName = device.Name;
                res.serialNumber = device.SerialNumber;
                res.assetStatus = device.Status;
                res.vehicleName = device.Parent?.Name;
                res.installDate = device.InstallDate != null ? String.valueOf(device.InstallDate) : null;
                res.isInstalled = device.Status == 'Installed';

                // Get contact
                List<Contact> contacts = [
                    SELECT Id, Name, Phone, Email
                    FROM Contact
                    WHERE AccountId = :device.AccountId
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];

                if (!contacts.isEmpty()) {
                    res.contactId = contacts[0].Id;
                    res.customerName = contacts[0].Name;
                    res.customerEmail = contacts[0].Email;
                    res.customerPhone = contacts[0].Phone;
                }

                res.success = true;
                res.message = device.Name + ' status: ' + device.Status;

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error getting install status: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
