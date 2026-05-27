/**
 * Quick Action: Simulate Battery Failure
 * Degrades Battery_Voltage AssetAttribute to 11.4V (below 11.8V threshold).
 * The platform asynchronously re-evaluates the RecordsetFltrCritMonitor,
 * setting IsWithinThreshold to false, which fires the VDD_Threshold_Breach_Trigger
 * flow → sends SMS alert to the customer.
 */
public with sharing class VDD_SimulateBatteryFailure {

    public class Request {
        @InvocableVariable(required=true description='Asset record ID of the VDD device')
        public String assetId;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='VDD Simulate Battery Failure' description='Degrades battery voltage below threshold to trigger health alert.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Asset device = [SELECT Id, Name FROM Asset WHERE Id = :req.assetId LIMIT 1];

                // 1. Find Battery_Voltage AttributeDefinition
                Id batteryDefId;
                for (AttributeDefinition ad : [
                    SELECT Id FROM AttributeDefinition WHERE DeveloperName = 'Battery_Voltage' LIMIT 1
                ]) {
                    batteryDefId = ad.Id;
                }

                if (batteryDefId == null) {
                    res.success = false;
                    res.message = 'Battery_Voltage AttributeDefinition not found.';
                    responses.add(res);
                    continue;
                }

                List<AssetAttribute> batteryAttrs = [
                    SELECT Id, AttributeValue FROM AssetAttribute
                    WHERE AssetId = :req.assetId AND AttributeDefinitionId = :batteryDefId
                    LIMIT 1
                ];

                if (batteryAttrs.isEmpty()) {
                    res.success = false;
                    res.message = 'No Battery_Voltage AssetAttribute found for this device. Run Complete Installation first.';
                    responses.add(res);
                    continue;
                }

                // 2. Update battery voltage to critically low value (below 11.8V threshold)
                AssetAttribute batteryAttr = batteryAttrs[0];
                batteryAttr.AttributeValue = '11.4';
                Database.updateImmediate(new List<AssetAttribute>{ batteryAttr });

                // 3. Update Last_Ping__c on the Asset to current timestamp
                device.Last_Ping__c = Datetime.now();
                update device;

                // The platform will asynchronously re-evaluate the RecordsetFltrCritMonitor
                // and update IsWithinThreshold from true to false, which fires the
                // VDD_Threshold_Breach_Trigger flow to send the SMS health alert.

                res.success = true;
                res.message = device.Name + ' battery voltage degraded to 11.4V (below 11.8V threshold). The platform will detect the breach and trigger a proactive health alert SMS to the customer.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error simulating battery failure: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
