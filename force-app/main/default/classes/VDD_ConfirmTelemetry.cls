/**
 * Topic 2: Post-Install Onboarding
 * Reads AssetAttribute records to verify device is reporting healthy telemetry.
 */
public with sharing class VDD_ConfirmTelemetry {

    public class Request {
        @InvocableVariable(required=true description='The Asset ID to check telemetry for')
        public String assetId;
    }

    public class Response {
        @InvocableVariable public String gpsAccuracy;
        @InvocableVariable public String signalStrength;
        @InvocableVariable public String batteryVoltage;
        @InvocableVariable public String lastPing;
        @InvocableVariable public String pingRate;
        @InvocableVariable public String deviceESN;
        @InvocableVariable public String telemetryStatus;
        @InvocableVariable public String allMetrics;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Confirm VDD Telemetry' description='Reads AssetAttribute records to verify device is reporting healthy telemetry.')
    public static List<Response> confirm(List<Request> requests) {
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

                res.gpsAccuracy = metrics.get('GPS_Fix_Accuracy');
                res.signalStrength = metrics.get('Cellular_Signal_Strength');
                res.batteryVoltage = metrics.get('Battery_Voltage');
                res.lastPing = metrics.get('Last_Ping_Time');
                res.pingRate = metrics.get('Ping_Rate_Seconds');
                res.deviceESN = metrics.get('Device_ESN');

                // Evaluate health
                Boolean gpsOk = false, signalOk = false, batteryOk = false;
                List<String> metricLines = new List<String>();

                if (res.gpsAccuracy != null) {
                    Decimal gps = Decimal.valueOf(res.gpsAccuracy);
                    gpsOk = gps < 15;
                    metricLines.add('GPS: ' + res.gpsAccuracy + 'm ' + (gpsOk ? '✓' : '✗'));
                }
                if (res.signalStrength != null) {
                    Decimal signal = Decimal.valueOf(res.signalStrength);
                    signalOk = signal > -100;
                    metricLines.add('Signal: ' + res.signalStrength + ' dBm ' + (signalOk ? '✓' : '✗'));
                }
                if (res.batteryVoltage != null) {
                    Decimal battery = Decimal.valueOf(res.batteryVoltage);
                    batteryOk = battery > 11.8;
                    metricLines.add('Battery: ' + res.batteryVoltage + 'V ' + (batteryOk ? '✓' : '✗'));
                }

                res.allMetrics = String.join(metricLines, ' | ');
                res.telemetryStatus = (gpsOk && signalOk && batteryOk) ? 'All Systems Go' : 'Issues Detected';
                res.success = true;
                res.message = 'Telemetry check complete: ' + res.telemetryStatus;

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error confirming telemetry: ' + e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}
