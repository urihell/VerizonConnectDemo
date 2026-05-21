ProductTransfer pt = [SELECT Id FROM ProductTransfer WHERE Id = '0Luaj000008rq0fCAA'];
pt.ShipmentStatus = 'In Transit';
pt.ShipmentTrackingNumber = '1Z999AA10123456784';
pt.ShipmentExpectedDeliveryDate = Date.newInstance(2026, 5, 22);
update pt;
System.debug('✓ ProductTransfer updated with shipment details');
