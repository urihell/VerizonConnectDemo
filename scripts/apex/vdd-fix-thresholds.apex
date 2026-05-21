/**
 * Fix VDD RecordsetFilterCriteriaRule values
 * The criteria represent the NORMAL range, not the alert condition.
 * Flip operators so healthy values fall WITHIN threshold.
 *
 * Healthy baseline values on VDD-400:
 *   GPS Fix Accuracy = 2.5 m  (healthy: < 15m)
 *   Cellular Signal  = -68 dBm (healthy: > -100 dBm)
 *   Battery Voltage  = 12.8 V  (healthy: > 11.8V)
 */

// GPS Accuracy: was GreaterThan 15 → change to LessThan 15
// (norm = GPS accuracy under 15m)
RecordsetFilterCriteriaRule gpsRule = [
    SELECT Id, Operator, Value
    FROM RecordsetFilterCriteriaRule
    WHERE Id = '0hKaj0000004qEXEAY'
];
gpsRule.Operator = 'LessThan';
gpsRule.Value = '15';
update gpsRule;
System.debug('✓ GPS Accuracy rule → LessThan 15 (norm: accuracy under 15m)');

// Signal Strength: was LessThan -100 → change to GreaterThan -100
// (norm = signal above -100 dBm)
RecordsetFilterCriteriaRule signalRule = [
    SELECT Id, Operator, Value
    FROM RecordsetFilterCriteriaRule
    WHERE Id = '0hKaj0000004qG9EAI'
];
signalRule.Operator = 'GreaterThan';
signalRule.Value = '-100';
update signalRule;
System.debug('✓ Signal Strength rule → GreaterThan -100 (norm: above -100 dBm)');

// Battery Voltage: was LessThan 11.8 → change to GreaterThan 11.8
// (norm = battery above 11.8V)
RecordsetFilterCriteriaRule batteryRule = [
    SELECT Id, Operator, Value
    FROM RecordsetFilterCriteriaRule
    WHERE Id = '0hKaj0000004qHlEAI'
];
batteryRule.Operator = 'GreaterThan';
batteryRule.Value = '11.8';
update batteryRule;
System.debug('✓ Battery Voltage rule → GreaterThan 11.8 (norm: above 11.8V)');

// Also rename the criteria to remove "Alert" since they now represent the norm
RecordsetFilterCriteria gpsCriteria = [SELECT Id, Name FROM RecordsetFilterCriteria WHERE Id = '0hraj0000005c33AAA'];
gpsCriteria.Name = 'VDD GPS Accuracy Norm';
gpsCriteria.Description = 'Normal range: GPS fix accuracy under 15 meters';
update gpsCriteria;

RecordsetFilterCriteria signalCriteria = [SELECT Id, Name FROM RecordsetFilterCriteria WHERE Id = '0hraj0000005c4fAAA'];
signalCriteria.Name = 'VDD Signal Strength Norm';
signalCriteria.Description = 'Normal range: cellular signal above -100 dBm';
update signalCriteria;

RecordsetFilterCriteria batteryCriteria = [SELECT Id, Name FROM RecordsetFilterCriteria WHERE Id = '0hraj0000005c6HAAQ'];
batteryCriteria.Name = 'VDD Battery Voltage Norm';
batteryCriteria.Description = 'Normal range: vehicle battery above 11.8V';
update batteryCriteria;

System.debug('✓ Renamed criteria to reflect normal range semantics');

// Verify final state
System.debug('=== VERIFICATION ===');
for (RecordsetFilterCriteriaRule r : [
    SELECT RecordsetFilterCriteria.Name, CriteriaField, Operator, Value
    FROM RecordsetFilterCriteriaRule
    WHERE RecordsetFilterCriteria.Name LIKE 'VDD%'
    ORDER BY RecordsetFilterCriteria.Name
]) {
    System.debug('  ' + r.RecordsetFilterCriteria.Name + ': ' + r.Operator + ' ' + r.Value);
}

// Check monitor status
for (RecordsetFltrCritMonitor m : [
    SELECT Name, IsWithinThreshold
    FROM RecordsetFltrCritMonitor
    WHERE AssetId = '02iaj000002m5XJAAY'
]) {
    System.debug('  Monitor: ' + m.Name + ' → IsWithinThreshold: ' + m.IsWithinThreshold);
}
