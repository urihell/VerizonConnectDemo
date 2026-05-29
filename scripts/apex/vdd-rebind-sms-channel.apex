// vdd-rebind-sms-channel.apex
// Run AFTER provisioning a new vendor-bound SMS channel via Setup > Messaging Settings.
// Auto-discovers the new channel, rewires Jim Stone's MessagingEndUser, fires the
// delivery flow, and verifies a ConversationEntry actually persists this time.
//
// Usage:
//   sf apex run --file scripts/apex/vdd-rebind-sms-channel.apex --target-org udabby@vzconnect26.demo

// 1) Find the new vendor-bound SMS channel (the one with ChannelDefinitionId populated)
List<MessagingChannel> bound = [
    SELECT Id, DeveloperName, MessagingPlatformKey, ChannelDefinitionId, IsActive, MessageType
    FROM MessagingChannel
    WHERE MessageType = 'Text' AND IsActive = true AND ChannelDefinitionId != null
    ORDER BY CreatedDate DESC
];

if (bound.isEmpty()) {
    System.debug(LoggingLevel.ERROR,
        'No SMS channel with ChannelDefinitionId found. Provision one in Setup > Messaging Settings first.');
    return;
}

MessagingChannel newChannel = bound[0];
System.debug('Using new channel: ' + newChannel.DeveloperName +
             ' (' + newChannel.MessagingPlatformKey + ', Id=' + newChannel.Id + ')');

// 2) Find Jim Stone's contact
Contact jim = [SELECT Id, Name, MobilePhone FROM Contact
               WHERE FirstName = 'Jim' AND LastName = 'Stone' LIMIT 1];
String e164 = '+17814900336';

// 3) Delete the old (orphaned) MessagingEndUser for Jim and recreate against the new channel
List<MessagingEndUser> existing = [
    SELECT Id, MessagingChannelId FROM MessagingEndUser WHERE ContactId = :jim.Id
];
if (!existing.isEmpty()) {
    System.debug('Deleting ' + existing.size() + ' existing MessagingEndUser record(s) for Jim');
    delete existing;
}

MessagingEndUser meu = new MessagingEndUser(
    ContactId = jim.Id,
    MessagingChannelId = newChannel.Id,
    MessagingPlatformKey = e164,
    Name = jim.Name,
    MessageType = 'Text'
);
insert meu;
System.debug('Created MessagingEndUser ' + meu.Id);

// 4) Trigger the delivery flow by toggling the shipment status
Shipment shp = [SELECT Id, Status FROM Shipment WHERE ShipmentNumber = 'SP-0002' LIMIT 1];
if (shp.Status == 'Delivered') {
    shp.Status = 'In Transit';
    update shp;
}
DateTime fireTime = System.now();
shp.Status = 'Delivered';
shp.ActualDeliveryDate = fireTime;
update shp;
System.debug('Shipment SP-0002 set to Delivered at ' + fireTime);

// 5) Verify a ConversationEntry was created (the real success signal)
List<ConversationEntry> entries = [
    SELECT Id, EntryType, MessageStatus, MessageStatusCode, Message, EntryTime, ActorName
    FROM ConversationEntry
    WHERE CreatedDate >= :fireTime.addSeconds(-5)
    ORDER BY EntryTime DESC
];

if (entries.isEmpty()) {
    System.debug(LoggingLevel.ERROR,
        'NO ConversationEntry created. Vendor binding may still be incomplete - check the channel in Setup.');
} else {
    System.debug('SUCCESS: ' + entries.size() + ' ConversationEntry record(s) created.');
    for (ConversationEntry e : entries) {
        System.debug('  ' + e.EntryType + ' | status=' + e.MessageStatus +
                     ' (' + e.MessageStatusCode + ') | ' + e.Message);
    }
}
