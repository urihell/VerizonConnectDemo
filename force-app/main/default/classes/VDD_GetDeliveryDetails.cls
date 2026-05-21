/**
 * Topic 1: Delivery Coordinator
 * Retrieves delivery details for a VDD device including customer, device IDs, vehicle, and location.
 */
public with sharing class VDD_GetDeliveryDetails {

    public class Request {
        @InvocableVariable(required=true description='The Asset ID for the delivered VDD device')
        public String assetId;
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
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Get VDD Delivery Details' description='Retrieves delivery details for a VDD device including customer contact, device IDs, vehicle, and location.')
    public static List<Response> getDetails(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Asset device = [
                    SELECT Id, Name, SerialNumber, Device_ESN__c, Status,
                           AccountId, Account.Name,
                           Parent.Name
                    FROM Asset
                    WHERE Id = :req.assetId
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
