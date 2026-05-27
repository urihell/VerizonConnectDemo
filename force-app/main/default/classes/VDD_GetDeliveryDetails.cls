/**
 * Topic 1: Delivery Coordinator
 * Retrieves delivery details for a VDD device including customer, device IDs, vehicle, and location.
 * Accepts either assetId (direct lookup) or contactId (finds most recent delivered asset for the contact's account).
 */
public with sharing class VDD_GetDeliveryDetails {

    public class Request {
        @InvocableVariable(required=false description='The Asset ID for the delivered VDD device. Optional if contactId is provided.')
        public String assetId;

        @InvocableVariable(required=false description='The Contact ID to look up the most recent delivered asset. Used when assetId is not available (e.g. SMS context).')
        public String contactId;
    }

    public class Response {
        @InvocableVariable public String customerName;
        @InvocableVariable public String customerPhone;
        @InvocableVariable public String customerEmail;
        @InvocableVariable public String contactId;
        @InvocableVariable public String accountId;
        @InvocableVariable public String serialNumber;
        @InvocableVariable public String deviceESN;
        @InvocableVariable public String assetName;
        @InvocableVariable public String accountName;
        @InvocableVariable public String vehicleName;
        @InvocableVariable public String deliveryAddress;
        @InvocableVariable public String assetId;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Get VDD Delivery Details' description='Retrieves delivery details for a VDD device including customer contact, device IDs, vehicle, and location. Pass assetId for direct lookup or contactId to find the most recent delivered asset.')
    public static List<Response> getDetails(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // Resolve the asset using whichever identifier is available
                String resolvedAssetId = req.assetId;

                // Path 1: contactId provided — find most recent delivered VDD-400 for this contact's account
                if (String.isBlank(resolvedAssetId) && String.isNotBlank(req.contactId)) {
                    Contact c = [SELECT AccountId FROM Contact WHERE Id = :req.contactId LIMIT 1];
                    List<Asset> deliveredAssets = [
                        SELECT Id FROM Asset
                        WHERE AccountId = :c.AccountId
                        AND Status = 'Delivered'
                        AND Name LIKE '%VDD-400%'
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                    ];
                    if (!deliveredAssets.isEmpty()) {
                        resolvedAssetId = deliveredAssets[0].Id;
                    }
                }

                // Path 2: No parameters at all — auto-resolve the most recent delivered VDD-400 asset (demo fallback)
                if (String.isBlank(resolvedAssetId)) {
                    List<Asset> deliveredAssets = [
                        SELECT Id FROM Asset
                        WHERE Status = 'Delivered'
                        AND Name LIKE '%VDD-400%'
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                    ];
                    if (!deliveredAssets.isEmpty()) {
                        resolvedAssetId = deliveredAssets[0].Id;
                    }
                }

                if (String.isBlank(resolvedAssetId)) {
                    res.success = false;
                    res.message = 'No delivered VDD-400 asset found.';
                    responses.add(res);
                    continue;
                }

                Asset device = [
                    SELECT Id, Name, SerialNumber, Device_ESN__c, Status,
                           AccountId, Account.Name,
                           Parent.Name
                    FROM Asset
                    WHERE Id = :resolvedAssetId
                    LIMIT 1
                ];

                res.assetName = device.Name;
                res.serialNumber = device.SerialNumber;
                res.deviceESN = device.Device_ESN__c;
                res.accountName = device.Account?.Name;
                res.accountId = device.Account?.Id;
                res.vehicleName = device.Parent?.Name;

                // Get primary contact from Account
                List<Contact> contacts = [
                    SELECT Id, Name, Phone, Email
                    FROM Contact
                    WHERE AccountId = :device.AccountId
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];

                if (!contacts.isEmpty()) {
                    Contact c = contacts[0];
                    res.contactId = c.Id;
                    res.customerName = c.Name;
                    res.customerPhone = c.Phone;
                    res.customerEmail = c.Email;
                }

                // Get delivery address from Location
                List<Schema.Location> locs = [
                    SELECT Id, Name, Latitude, Longitude
                    FROM Location
                    WHERE Name LIKE '%Fleet Yard%'
                    LIMIT 1
                ];
                res.deliveryAddress = !locs.isEmpty() ? locs[0].Name : 'Fleet Yard, Old Bridge, NJ';

                res.assetId = device.Id;
                res.success = true;
                res.message = 'Delivery details retrieved for ' + device.Name;

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error retrieving delivery details: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}