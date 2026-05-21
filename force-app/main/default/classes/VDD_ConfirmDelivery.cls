/**
 * Quick Action: Confirm Delivery
 * Sets the current Asset status to "Delivered" — triggering Flow 1 → Agent Topic 1.
 * Designed to be called from a Quick Action or Screen Flow on the Asset record page.
 */
public with sharing class VDD_ConfirmDelivery {

    public class Request {
        @InvocableVariable(required=true description='Asset record ID')
        public String assetId;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='VDD Confirm Delivery' description='Sets Asset status to Delivered and updates child equipment/component statuses.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // Update the target device asset to Delivered
                Asset device = [SELECT Id, Name, Status FROM Asset WHERE Id = :req.assetId LIMIT 1];
                device.Status = 'Delivered';
                update device;

                res.success = true;
                res.message = device.Name + ' status updated to Delivered. Delivery Coordinator agent will contact the customer.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error confirming delivery: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
