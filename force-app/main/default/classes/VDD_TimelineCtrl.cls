/**
 * Controller for vddAssetTimeline LWC.
 * Returns lifecycle stage data for the horizontal timeline visualization.
 */
public with sharing class VDD_TimelineCtrl {

    public class TimelineStage {
        @AuraEnabled public String stage;
        @AuraEnabled public String icon;
        @AuraEnabled public String status; // completed, current, upcoming
        @AuraEnabled public String timestamp;
        @AuraEnabled public String color;
    }

    @AuraEnabled(cacheable=true)
    public static List<TimelineStage> getTimelineData(String recordId) {
        Asset a = [
            SELECT Id, Name, Status, CreatedDate, InstallDate, Last_Ping__c
            FROM Asset
            WHERE Id = :recordId
            LIMIT 1
        ];

        List<TimelineStage> stages = new List<TimelineStage>();
        String currentStatus = a.Status != null ? a.Status : '';

        // Define stage order
        List<String> stageOrder = new List<String>{
            'Ordered', 'Shipped', 'Delivered', 'Installed', 'Operational'
        };
        Map<String, String> stageIcons = new Map<String, String>{
            'Ordered' => 'standard:orders',
            'Shipped' => 'standard:shipment',
            'Delivered' => 'standard:product_transfer',
            'Installed' => 'standard:service_resource',
            'Operational' => 'standard:connected_apps'
        };

        // Map asset statuses to stage indices
        Map<String, Integer> statusToStageIndex = new Map<String, Integer>{
            'Purchased' => 0,
            'Manufactured' => 0,
            'Registered' => 0,
            'Shipped' => 1,
            'Delivered' => 2,
            'Installed' => 3
        };

        // Determine current stage index
        Integer currentIndex = -1;
        if (a.Last_Ping__c != null && currentStatus == 'Installed') {
            currentIndex = 4; // Operational
        } else if (statusToStageIndex.containsKey(currentStatus)) {
            currentIndex = statusToStageIndex.get(currentStatus);
        }

        for (Integer i = 0; i < stageOrder.size(); i++) {
            TimelineStage ts = new TimelineStage();
            ts.stage = stageOrder[i];
            ts.icon = stageIcons.get(stageOrder[i]);

            if (i < currentIndex) {
                ts.status = 'completed';
                ts.color = 'success';
            } else if (i == currentIndex) {
                ts.status = 'current';
                ts.color = i == 4 ? 'success' : 'warning';
            } else {
                ts.status = 'upcoming';
                ts.color = 'neutral';
            }

            // Assign timestamps
            if (stageOrder[i] == 'Ordered') {
                ts.timestamp = String.valueOf(a.CreatedDate);
            } else if (stageOrder[i] == 'Installed' && a.InstallDate != null) {
                ts.timestamp = String.valueOf(a.InstallDate);
            } else if (stageOrder[i] == 'Operational' && a.Last_Ping__c != null) {
                ts.timestamp = String.valueOf(a.Last_Ping__c);
            }

            stages.add(ts);
        }

        return stages;
    }
}
