/**
 * VDD_BuildEquipmentSummary
 * Builds a compact equipment summary from ProductTransfer records
 * linked to a Shipment. Used by the VDD Delivery SMS Notification flow.
 *
 * Keeps output short to stay within SMS character limits.
 * Example output: "33 GPS trackers, 33 dashcams + 3 more items (165 units total)"
 */
public with sharing class VDD_BuildEquipmentSummary {

    public class Request {
        @InvocableVariable(required=true description='Shipment record ID')
        public String shipmentId;
    }

    public class Response {
        @InvocableVariable(description='Formatted equipment summary string')
        public String summary;
    }

    // Short display names to keep SMS compact
    private static final Map<String, String> SHORT_NAMES = new Map<String, String>{
        'VDD-400 GPS Tracking Unit' => 'GPS trackers',
        'DC-200 Dual Dashcam' => 'dashcams',
        'External GPS Antenna' => 'antennas',
        'OBD-II Y-Harness' => 'harnesses',
        'IoT SIM Card (CAT-M1)' => 'SIM cards'
    };

    @InvocableMethod(label='VDD Build Equipment Summary' description='Builds equipment summary from ProductTransfers on a Shipment.')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            List<ProductTransfer> transfers = [
                SELECT Product2.Name, QuantitySent
                FROM ProductTransfer
                WHERE ShipmentId = :req.shipmentId
                ORDER BY Product2.Name ASC
            ];

            Integer totalUnits = 0;
            List<String> lines = new List<String>();
            for (ProductTransfer pt : transfers) {
                Integer qty = (pt.QuantitySent != null) ? pt.QuantitySent.intValue() : 0;
                totalUnits += qty;
                String fullName = (pt.Product2 != null && pt.Product2.Name != null)
                    ? pt.Product2.Name : 'equipment';
                String shortName = SHORT_NAMES.containsKey(fullName)
                    ? SHORT_NAMES.get(fullName) : fullName;
                lines.add(qty + ' ' + shortName);
            }

            if (lines.isEmpty()) {
                res.summary = 'your equipment order';
            } else if (lines.size() <= 2) {
                // Short enough to list all
                res.summary = String.join(lines, ', ');
            } else {
                // Show first 2 items + count of remaining
                List<String> shown = new List<String>{ lines[0], lines[1] };
                Integer remaining = lines.size() - 2;
                res.summary = String.join(shown, ', ') + ' + ' + remaining + ' more (' + totalUnits + ' units)';
            }
            responses.add(res);
        }

        return responses;
    }
}