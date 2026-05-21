/**
 * Controller for vddHealthDashboard LWC.
 * Reads AssetAttribute records and RecordsetFltrCritMonitor status for health gauges.
 */
public with sharing class VDD_HealthCtrl {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getHealthMetrics(String assetId) {
        Map<String, String> metrics = new Map<String, String>();
        for (AssetAttribute aa : [
            SELECT AttributeName, AttributeValue, AttributeDefinition.DeveloperName
            FROM AssetAttribute
            WHERE AssetId = :assetId
        ]) {
            metrics.put(aa.AttributeDefinition.DeveloperName, aa.AttributeValue);
        }
        return metrics;
        // Returns: {GPS_Fix_Accuracy: '2.3', Cellular_Signal_Strength: '-72', Battery_Voltage: '14.2', ...}
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getThresholdStatus(String assetId) {
        List<Map<String, Object>> monitors = new List<Map<String, Object>>();
        for (RecordsetFltrCritMonitor m : [
            SELECT Name, IsWithinThreshold, RecordsetFilterCriteria.Name
            FROM RecordsetFltrCritMonitor
            WHERE AssetId = :assetId
        ]) {
            monitors.add(new Map<String, Object>{
                'name' => m.RecordsetFilterCriteria.Name,
                'withinThreshold' => m.IsWithinThreshold
            });
        }
        return monitors;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAssetInfo(String assetId) {
        Asset a = [
            SELECT Id, Name, Status, SerialNumber, Device_ESN__c, Last_Ping__c,
                   Account.Name, Parent.Name
            FROM Asset
            WHERE Id = :assetId
            LIMIT 1
        ];
        return new Map<String, Object>{
            'name' => a.Name,
            'status' => a.Status,
            'serialNumber' => a.SerialNumber,
            'deviceESN' => a.Device_ESN__c,
            'lastPing' => a.Last_Ping__c,
            'accountName' => a.Account?.Name,
            'vehicleName' => a.Parent?.Name
        };
    }
}
