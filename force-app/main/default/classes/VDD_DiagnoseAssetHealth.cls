/**
 * Topic 3: Proactive Health Monitor
 * Reads all AssetAttribute records for the asset and produces a diagnostic summary.
 */
public with sharing class VDD_DiagnoseAssetHealth {

    public class Request {
        @InvocableVariable(required=true description='The Asset ID to diagnose')
        public String assetId;
        @InvocableVariable(required=true description='Name of the threshold that was breached')
        public String thresholdName;
    }

    public class Response {
        @InvocableVariable public String diagnosis;
        @InvocableVariable public String severity;
        @InvocableVariable public String recommendedAction;
        @InvocableVariable public String allMetrics;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Diagnose Asset Health' description='Reads all AssetAttribute records for the asset and produces a diagnostic summary with severity and recommended action.')
    public static List<Response> diagnose(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Map<String, String> metrics = new Map<String, String>();
                for (AssetAttribute aa : [
                    SELECT AttributeName, AttributeValue, AttributeDefinition.DeveloperName
                    FROM AssetAttribute
                    WHERE AssetId = :req.assetId
                ]) {
                    metrics.put(aa.AttributeDefinition.DeveloperName, aa.AttributeValue);
                }

                List<String> metricLines = new List<String>();
                List<String> issues = new List<String>();

                // GPS Accuracy
                if (metrics.containsKey('GPS_Fix_Accuracy')) {
                    Decimal gps = Decimal.valueOf(metrics.get('GPS_Fix_Accuracy'));
                    String gpsMark = gps < 15 ? '✓' : '✗';
                    metricLines.add('GPS: ' + metrics.get('GPS_Fix_Accuracy') + 'm ' + gpsMark);
                    if (gps >= 15) issues.add('GPS accuracy degraded at ' + gps + 'm (threshold: <15m). Possible antenna obstruction or device malfunction.');
                }

                // Signal Strength
                if (metrics.containsKey('Cellular_Signal_Strength')) {
                    Decimal signal = Decimal.valueOf(metrics.get('Cellular_Signal_Strength'));
                    String sigMark = signal > -100 ? '✓' : '✗';
                    metricLines.add('Signal: ' + metrics.get('Cellular_Signal_Strength') + ' dBm ' + sigMark);
                    if (signal <= -100) issues.add('Cellular signal critically weak at ' + signal + ' dBm (threshold: >-100 dBm). Check antenna connection or SIM card.');
                }

                // Battery Voltage
                if (metrics.containsKey('Battery_Voltage')) {
                    Decimal battery = Decimal.valueOf(metrics.get('Battery_Voltage'));
                    String batMark = battery > 11.8 ? '✓' : '✗';
                    metricLines.add('Battery: ' + metrics.get('Battery_Voltage') + 'V ' + batMark);
                    if (battery <= 11.8) issues.add('Battery voltage critically low at ' + battery + 'V (threshold: >11.8V). Check vehicle alternator or replace battery.');
                }

                res.allMetrics = String.join(metricLines, ' | ');

                if (issues.isEmpty()) {
                    res.diagnosis = 'All metrics within normal range. Threshold breach may have been transient.';
                    res.severity = 'Low';
                    res.recommendedAction = 'Continue monitoring. No immediate action required.';
                } else {
                    res.diagnosis = String.join(issues, ' ');
                    res.severity = issues.size() > 1 ? 'Critical' : 'Warning';
                    res.recommendedAction = issues.size() > 1
                        ? 'Multiple issues detected. Dispatch field technician immediately for full diagnostic.'
                        : 'Schedule field service visit within 48 hours to inspect and resolve.';
                }

                res.success = true;
                res.message = 'Diagnosis complete for asset ' + req.assetId + ': ' + res.severity;

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error diagnosing asset health: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}