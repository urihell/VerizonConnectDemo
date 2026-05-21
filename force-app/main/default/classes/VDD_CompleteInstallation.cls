/**
 * Quick Action: Complete Installation
 * Sets Asset status to "Installed", creates AssetAttribute records with healthy values,
 * creates RecordsetFltrCritMonitor records — triggering Flow 2 → Agent Topic 2.
 */
public with sharing class VDD_CompleteInstallation {

    public class Request {
        @InvocableVariable(required=true description='Asset record ID of the VDD device')
        public String assetId;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='VDD Complete Installation' description='Sets Asset to Installed, creates healthy AssetAttributes and threshold monitors.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                // 1. Update asset status to Installed
                Asset device = [SELECT Id, Name, Status FROM Asset WHERE Id = :req.assetId LIMIT 1];
                device.Status = 'Installed';
                device.InstallDate = Date.today();
                device.Last_Ping__c = Datetime.now();
                update device;

                // 2. Delete any existing AssetAttributes (clean slate)
                List<AssetAttribute> existingAttrs = [
                    SELECT Id FROM AssetAttribute WHERE AssetId = :req.assetId
                ];
                if (!existingAttrs.isEmpty()) {
                    Database.deleteImmediate(existingAttrs);
                }

                // 3. Query AttributeDefinition IDs by DeveloperName
                Map<String, Id> attrDefMap = new Map<String, Id>();
                for (AttributeDefinition ad : [
                    SELECT Id, DeveloperName FROM AttributeDefinition
                    WHERE DeveloperName IN ('GPS_Fix_Accuracy', 'Cellular_Signal_Strength', 'Battery_Voltage',
                                            'Device_ESN', 'Last_Ping_Time', 'Ping_Rate_Seconds', 'Temperature')
                ]) {
                    attrDefMap.put(ad.DeveloperName, ad.Id);
                }

                // 4. Create healthy baseline AssetAttributes
                List<AssetAttribute> newAttrs = new List<AssetAttribute>();
                if (attrDefMap.containsKey('GPS_Fix_Accuracy'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('GPS_Fix_Accuracy'), AttributeValue = '2.5'));
                if (attrDefMap.containsKey('Cellular_Signal_Strength'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('Cellular_Signal_Strength'), AttributeValue = '-68'));
                if (attrDefMap.containsKey('Battery_Voltage'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('Battery_Voltage'), AttributeValue = '12.8'));
                if (attrDefMap.containsKey('Device_ESN'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('Device_ESN'), AttributeValue = 'VDD400-ESN-0847'));
                if (attrDefMap.containsKey('Last_Ping_Time'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('Last_Ping_Time'), AttributeValue = String.valueOf(Datetime.now().addMinutes(-5))));
                if (attrDefMap.containsKey('Ping_Rate_Seconds'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('Ping_Rate_Seconds'), AttributeValue = '30'));
                if (attrDefMap.containsKey('Temperature'))
                    newAttrs.add(new AssetAttribute(AssetId = req.assetId, AttributeDefinitionId = attrDefMap.get('Temperature'), AttributeValue = '38'));

                if (!newAttrs.isEmpty()) {
                    Database.insertImmediate(newAttrs);
                }

                // 5. Delete existing monitors, then recreate
                List<RecordsetFltrCritMonitor> existingMonitors = [
                    SELECT Id FROM RecordsetFltrCritMonitor WHERE AssetId = :req.assetId
                ];
                if (!existingMonitors.isEmpty()) {
                    delete existingMonitors;
                }

                // Query threshold criteria
                Map<String, Id> criteriaMap = new Map<String, Id>();
                for (RecordsetFilterCriteria rfc : [
                    SELECT Id, Name FROM RecordsetFilterCriteria
                    WHERE Name LIKE 'VDD%Norm'
                ]) {
                    criteriaMap.put(rfc.Name, rfc.Id);
                }

                List<RecordsetFltrCritMonitor> monitors = new List<RecordsetFltrCritMonitor>();
                if (criteriaMap.containsKey('VDD GPS Accuracy Norm'))
                    monitors.add(new RecordsetFltrCritMonitor(Name = 'VDD GPS Accuracy', RecordsetFilterCriteriaId = criteriaMap.get('VDD GPS Accuracy Norm'), AssetId = req.assetId));
                if (criteriaMap.containsKey('VDD Signal Strength Norm'))
                    monitors.add(new RecordsetFltrCritMonitor(Name = 'VDD Signal Strength', RecordsetFilterCriteriaId = criteriaMap.get('VDD Signal Strength Norm'), AssetId = req.assetId));
                if (criteriaMap.containsKey('VDD Battery Voltage Norm'))
                    monitors.add(new RecordsetFltrCritMonitor(Name = 'VDD Battery Voltage', RecordsetFilterCriteriaId = criteriaMap.get('VDD Battery Voltage Norm'), AssetId = req.assetId));

                if (!monitors.isEmpty()) {
                    insert monitors;
                }

                res.success = true;
                res.message = device.Name + ' installed successfully. ' + newAttrs.size() + ' health metrics created. ' + monitors.size() + ' threshold monitors active. Post-Install Onboarding agent will send welcome message.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error completing installation: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
