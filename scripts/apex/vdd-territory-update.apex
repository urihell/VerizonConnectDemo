/**
 * VDD Territory Update Script
 * ----------------------------
 * Updates the *San Francisco Service Territory to *New Jersey
 * for the Black Rock Paving demo (Old Bridge, NJ).
 *
 * Run via:  sf apex run --file scripts/apex/vdd-territory-update.apex --target-org verizon-connect-bj550e
 */

// Update the *San Francisco territory to *New Jersey
Id territoryId = '0Hhaj000001EXJiCAO';  // *San Francisco

ServiceTerritory st = [SELECT Id, Name, Street, City, State, PostalCode, Country, Latitude, Longitude FROM ServiceTerritory WHERE Id = :territoryId LIMIT 1];

System.debug('BEFORE: ' + st.Name + ' — ' + st.City + ', ' + st.State);

st.Name = '*New Jersey';
st.Street = '200 Route 9 North';
st.City = 'Old Bridge';
st.State = 'NJ';
st.PostalCode = '08857';
st.Country = 'USA';
st.Latitude = 40.4154;
st.Longitude = -74.2643;

update st;

System.debug('AFTER: ' + st.Name + ' — ' + st.City + ', ' + st.State);
System.debug('✓ Service Territory updated to *New Jersey (Old Bridge, NJ)');
System.debug('  9 Service Territory Members remain assigned to this territory.');
