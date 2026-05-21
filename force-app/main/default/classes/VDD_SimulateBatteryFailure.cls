/**
 * Quick Action: Simulate Battery Failure
 * Degrades Battery_Voltage AssetAttribute to 11.4V (below 11.8V threshold),
 * deletes and recreates RecordsetFltrCritMonitor to force re-evaluation —
 * triggering Flow 3 → Agent Topic 3.
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

    @InvocableMethod(label='VDD Simulate Battery Failure' description='Degrades battery voltage below threshold and resets monitors to trigger health alert.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Asset device = [SELECT Id, Name FROM Asset WHERE Id = :req.assetId LIMIT 1];

                // 1. Update Battery_Voltage AssetAttribute to 11.4V (below 11.8V norm threshold)
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

                // Update battery voltage to critically low value
                AssetAttribute batteryAttr = batteryAttrs[0];
                batteryAttr.AttributeValue = '11.4';
                Database.updateImmediate(new List<AssetAttribute>{ batteryAttr });

                // 2. Delete and recreate the Battery Voltage monitor to force re-evaluation
                List<RecordsetFltrCritMonitor> existingMonitors = [
                    SELECT Id, Name FROM RecordsetFltrCritMonitor
                    WHERE AssetId = :req.assetId AND Name = 'VDD Battery Voltage'
                ];
                if (!existingMonitors.isEmpty()) {
                    delete existingMonitors;
                }

                // Recreate the monitor so the platform re-evaluates against the new value
                Id batteryCriteriaId;
                for (RecordsetFilterCriteria rfc : [
                    SELECT Id FROM RecordsetFilterCriteria WHERE Name = 'VDD Battery Voltage Norm' LIMIT 1
                ]) {
                    batteryCriteriaId = rfc.Id;
                }

                if (batteryCriteriaId != null) {
                    insert new RecordsetFltrCritMonitor(
                        Name = 'VDD Battery Voltage',
                        RecordsetFilterCriteriaId = batteryCriteriaId,
                        AssetId = req.assetId
                    );
                }

                res.success = true;
                res.message = device.Name + ' battery voltage degraded to 11.4V (below 11.8V threshold). Threshold monitor recreated — Proactive Health Monitor agent will detect the breach and create a replacement case.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error simulating battery failure: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
