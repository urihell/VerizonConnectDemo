/**
 * Topic 2: Post-Install Onboarding
 * Reads Asset and parent vehicle info after installation is complete.
 * Accepts either assetId (direct lookup) or contactId (finds most recent installed asset for the contact's account).
 */
public with sharing class VDD_GetInstallStatus {

    public class Request {
        @InvocableVariable(required=false description='The Asset ID for the installed VDD device. Optional if contactId is provided.')
        public String assetId;

        @InvocableVariable(required=false description='The Contact ID to look up the most recent installed asset. Used when assetId is not available (e.g. SMS context).')
        public String contactId;
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
        @InvocableVariable public String assetId;
        @InvocableVariable public String assetStatus;
        @InvocableVariable public Boolean isInstalled;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Get VDD Install Status' description='Retrieves installation status and details for a VDD device. Pass assetId for direct lookup or contactId to find the most recent installed asset.')
    public static List<Response> getStatus(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // Resolve the asset using whichever identifier is available
                String resolvedAssetId = req.assetId;

                // Path 1: contactId provided — find most recent installed VDD-400 for this contact's account
                if (String.isBlank(resolvedAssetId) && String.isNotBlank(req.contactId)) {
                    Contact c = [SELECT AccountId FROM Contact WHERE Id = :req.contactId LIMIT 1];
                    List<Asset> installedAssets = [
                        SELECT Id FROM Asset
                        WHERE AccountId = :c.AccountId
                        AND Status = 'Installed'
                        AND Name LIKE '%VDD-400%'
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                    ];
                    if (!installedAssets.isEmpty()) {
                        resolvedAssetId = installedAssets[0].Id;
                    }
                }

                // Path 2: No parameters at all — auto-resolve the most recent installed VDD-400 asset (demo fallback)
                if (String.isBlank(resolvedAssetId)) {
                    List<Asset> installedAssets = [
                        SELECT Id FROM Asset
                        WHERE Status = 'Installed'
                        AND Name LIKE '%VDD-400%'
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                    ];
                    if (!installedAssets.isEmpty()) {
                        resolvedAssetId = installedAssets[0].Id;
                    }
                }

                if (String.isBlank(resolvedAssetId)) {
                    res.success = false;
                    res.message = 'No installed VDD-400 asset found.';
                    responses.add(res);
                    continue;
                }

                Asset device = [
                    SELECT Id, Name, SerialNumber, Status, InstallDate,
                           AccountId, Account.Name, Parent.Name
                    FROM Asset
                    WHERE Id = :resolvedAssetId
                    LIMIT 1
                ];

                res.assetId = device.Id;
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
