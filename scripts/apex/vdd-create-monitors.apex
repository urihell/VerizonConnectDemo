/**
 * Create RecordsetFltrCritMonitor records for VDD-400 tracker
 * Links the VDD threshold criteria to the VDD-400 asset so the
 * Threshold Monitoring component can display them on the record page.
 */

// VDD-400 tracker asset
Id vddTrackerId = '02iaj000002m5XJAAY';

// VDD RecordsetFilterCriteria IDs
Id gpsAccuracyCriteria   = '0hraj0000005c33AAA';  // VDD GPS Accuracy Alert
Id signalStrengthCriteria = '0hraj0000005c4fAAA';  // VDD Signal Strength Alert
Id batteryVoltageCriteria = '0hraj0000005c6HAAQ';  // VDD Battery Voltage Alert

// Check if monitors already exist for this asset
List<RecordsetFltrCritMonitor> existing = [
    SELECT Id, Name, RecordsetFilterCriteriaId
    FROM RecordsetFltrCritMonitor
    WHERE AssetId = :vddTrackerId
];

if (!existing.isEmpty()) {
    System.debug('⚠ ' + existing.size() + ' monitors already exist for VDD-400. Deleting first...');
    delete existing;
}

// Create monitors linking each threshold criteria to the VDD-400 asset
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

System.debug('=== VDD THRESHOLD MONITORS CREATED ===');
for (RecordsetFltrCritMonitor m : monitors) {
    System.debug('✓ Created monitor: ' + m.Name + ' (Id: ' + m.Id + ')');
}

// Verify
List<RecordsetFltrCritMonitor> verify = [
    SELECT Id, Name, RecordsetFilterCriteria.Name, IsWithinThreshold
    FROM RecordsetFltrCritMonitor
    WHERE AssetId = :vddTrackerId
];
System.debug('=== VERIFICATION ===');
for (RecordsetFltrCritMonitor v : verify) {
    System.debug('  ' + v.Name + ' → IsWithinThreshold: ' + v.IsWithinThreshold);
}
