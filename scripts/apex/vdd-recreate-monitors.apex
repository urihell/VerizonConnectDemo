/**
 * Recreate VDD threshold monitors to force platform re-evaluation
 * after criteria rules were updated.
 */
Id vddTrackerId = '02iaj000002m5XJAAY';

// Delete existing monitors
List<RecordsetFltrCritMonitor> existing = [
    SELECT Id, Name FROM RecordsetFltrCritMonitor
    WHERE AssetId = :vddTrackerId
];
if (!existing.isEmpty()) {
    delete existing;
    System.debug('Deleted ' + existing.size() + ' monitors');
}

// Recreate
Id gpsAccuracyCriteria    = '0hraj0000005c33AAA';
Id signalStrengthCriteria = '0hraj0000005c4fAAA';
Id batteryVoltageCriteria = '0hraj0000005c6HAAQ';

List<RecordsetFltrCritMonitor> monitors = new List<RecordsetFltrCritMonitor>();
monitors.add(new RecordsetFltrCritMonitor(
    Name = 'VDD GPS Accuracy',
    RecordsetFilterCriteriaId = gpsAccuracyCriteria,
    AssetId = vddTrackerId
));
monitors.add(new RecordsetFltrCritMonitor(
    Name = 'VDD Signal Strength',
    RecordsetFilterCriteriaId = signalStrengthCriteria,
    AssetId = vddTrackerId
));
monitors.add(new RecordsetFltrCritMonitor(
    Name = 'VDD Battery Voltage',
    RecordsetFilterCriteriaId = batteryVoltageCriteria,
    AssetId = vddTrackerId
));
insert monitors;
System.debug('Created ' + monitors.size() + ' monitors');

// Verify immediately
for (RecordsetFltrCritMonitor m : [
    SELECT Name, IsWithinThreshold, RecordsetFilterCriteria.Name
    FROM RecordsetFltrCritMonitor
    WHERE AssetId = :vddTrackerId
]) {
    System.debug('  ' + m.Name + ' → IsWithinThreshold: ' + m.IsWithinThreshold);
}
