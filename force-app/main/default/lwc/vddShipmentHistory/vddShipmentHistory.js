import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import STATUS_FIELD from '@salesforce/schema/Shipment.Status';
import CREATED_DATE from '@salesforce/schema/Shipment.CreatedDate';
import EXPECTED_DATE from '@salesforce/schema/Shipment.ExpectedDeliveryDate';
import ACTUAL_DATE from '@salesforce/schema/Shipment.ActualDeliveryDate';
import SHIP_FROM_CITY from '@salesforce/schema/Shipment.ShipFromCity';
import SHIP_FROM_STATE from '@salesforce/schema/Shipment.ShipFromState';
import SHIP_TO_CITY from '@salesforce/schema/Shipment.ShipToCity';
import SHIP_TO_STATE from '@salesforce/schema/Shipment.ShipToState';
import SHIP_TO_NAME from '@salesforce/schema/Shipment.ShipToName';

const FIELDS = [
    STATUS_FIELD, CREATED_DATE, EXPECTED_DATE, ACTUAL_DATE,
    SHIP_FROM_CITY, SHIP_FROM_STATE, SHIP_TO_CITY, SHIP_TO_STATE, SHIP_TO_NAME
];

export default class VddShipmentHistory extends LightningElement {
    @api recordId;
    shipment;
    error;
    _expanded = true;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredShipment({ error, data }) {
        if (data) {
            this.shipment = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.shipment = undefined;
        }
    }

    get isLoading() {
        return !this.shipment && !this.error;
    }

    get isExpanded() {
        return this._expanded;
    }

    get toggleLabel() {
        return this._expanded ? 'Hide Details' : 'Show Details';
    }

    handleToggle() {
        this._expanded = !this._expanded;
    }

    get status() {
        return this.shipment ? getFieldValue(this.shipment, STATUS_FIELD) : '';
    }

    get originLocation() {
        if (!this.shipment) return '';
        const city = getFieldValue(this.shipment, SHIP_FROM_CITY) || '';
        const state = getFieldValue(this.shipment, SHIP_FROM_STATE) || '';
        return [city, state].filter(Boolean).join(', ') + (city || state ? ', United States' : '');
    }

    get destinationLocation() {
        if (!this.shipment) return '';
        const city = getFieldValue(this.shipment, SHIP_TO_CITY) || '';
        const state = getFieldValue(this.shipment, SHIP_TO_STATE) || '';
        return [city, state].filter(Boolean).join(', ') + (city || state ? ', United States' : '');
    }

    get destinationName() {
        return this.shipment ? (getFieldValue(this.shipment, SHIP_TO_NAME) || '') : '';
    }

    get events() {
        if (!this.shipment) return [];

        const st = this.status;
        const createdRaw = getFieldValue(this.shipment, CREATED_DATE);
        const expectedRaw = getFieldValue(this.shipment, EXPECTED_DATE);
        const actualRaw = getFieldValue(this.shipment, ACTUAL_DATE);

        const created = createdRaw ? new Date(createdRaw) : new Date();
        const origin = this.originLocation;
        const dest = this.destinationLocation;

        // Build a realistic event history based on shipment status
        const timeline = [];

        // --- Order Placed (always shown) ---
        timeline.push({
            id: 'evt-01',
            date: this._formatDate(created),
            time: this._formatTime(created),
            title: 'Order Processed',
            subtitle: 'Shipment order created and processing initiated',
            location: origin,
            isBold: false,
            isFirst: false
        });

        // --- Picked Up / Label Created ---
        const pickup = new Date(created.getTime() + 2 * 60 * 60 * 1000); // +2 hours
        timeline.push({
            id: 'evt-02',
            date: this._formatDate(pickup),
            time: this._formatTime(pickup),
            title: 'Label Created',
            subtitle: 'Shipping label created, package ready for pickup',
            location: origin,
            isBold: false,
            isFirst: false
        });

        const pickup2 = new Date(created.getTime() + 5 * 60 * 60 * 1000); // +5 hours
        timeline.push({
            id: 'evt-03',
            date: this._formatDate(pickup2),
            time: this._formatTime(pickup2),
            title: 'Picked Up',
            subtitle: 'Package picked up by carrier',
            location: origin,
            isBold: false,
            isFirst: false
        });

        if (st === 'Shipped' || st === 'In Transit' || st === 'Out for Delivery' || st === 'Delivered') {
            // --- Departed Facility ---
            const departed = new Date(created.getTime() + 10 * 60 * 60 * 1000);
            timeline.push({
                id: 'evt-04',
                date: this._formatDate(departed),
                time: this._formatTime(departed),
                title: 'Departed from Facility',
                subtitle: null,
                location: origin,
                isBold: false,
                isFirst: false
            });
        }

        if (st === 'In Transit' || st === 'Out for Delivery' || st === 'Delivered') {
            // --- In Transit events ---
            const transit1 = new Date(created.getTime() + 24 * 60 * 60 * 1000);
            timeline.push({
                id: 'evt-05',
                date: this._formatDate(transit1),
                time: this._formatTime(transit1),
                title: 'Arrived at Facility',
                subtitle: null,
                location: this._transitHub(origin, dest),
                isBold: false,
                isFirst: false
            });

            const transit2 = new Date(transit1.getTime() + 4 * 60 * 60 * 1000);
            timeline.push({
                id: 'evt-06',
                date: this._formatDate(transit2),
                time: this._formatTime(transit2),
                title: 'Departed from Facility',
                subtitle: null,
                location: this._transitHub(origin, dest),
                isBold: false,
                isFirst: false
            });

            const transit3 = new Date(transit2.getTime() + 18 * 60 * 60 * 1000);
            timeline.push({
                id: 'evt-07',
                date: this._formatDate(transit3),
                time: this._formatTime(transit3),
                title: 'Arrived at Facility',
                subtitle: null,
                location: dest,
                isBold: false,
                isFirst: false
            });

            const processing = new Date(transit3.getTime() + 1 * 60 * 60 * 1000);
            timeline.push({
                id: 'evt-08',
                date: this._formatDate(processing),
                time: this._formatTime(processing),
                title: 'Processing at Facility',
                subtitle: null,
                location: dest,
                isBold: false,
                isFirst: false
            });

            // --- On the Way ---
            const onTheWay = new Date(processing.getTime() + 2 * 60 * 60 * 1000);
            timeline.push({
                id: 'evt-09',
                date: this._formatDate(onTheWay),
                time: this._formatTime(onTheWay),
                title: 'On the Way',
                subtitle: 'Processing at local distribution center',
                location: dest,
                isBold: true,
                isFirst: false
            });
        }

        if (st === 'Out for Delivery' || st === 'Delivered') {
            const expected = expectedRaw ? new Date(expectedRaw) : new Date();
            const outTime = new Date(expected.getTime());
            outTime.setHours(10, 20, 0);
            timeline.push({
                id: 'evt-10',
                date: this._formatDate(outTime),
                time: this._formatTime(outTime),
                title: 'Out for Delivery',
                subtitle: 'Out For Delivery Today',
                location: dest,
                isBold: true,
                isFirst: false
            });
        }

        if (st === 'Delivered') {
            const actual = actualRaw ? new Date(actualRaw) : new Date();
            timeline.push({
                id: 'evt-11',
                date: this._formatDate(actual),
                time: this._formatTime(actual),
                title: 'Delivered',
                subtitle: 'DELIVERED',
                location: dest.toUpperCase(),
                isBold: true,
                isFirst: true
            });
        }

        // Reverse chronological order (most recent first) like UPS
        const reversed = timeline.reverse();

        // Mark the first (most recent) event
        if (reversed.length > 0) {
            reversed[0].isFirst = true;
        }

        return reversed;
    }

    _formatDate(d) {
        return d.toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
    }

    _formatTime(d) {
        return d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true }).toUpperCase();
    }

    _transitHub(origin, dest) {
        // Generate a realistic transit hub between origin and destination
        const hubs = [
            'Memphis, TN, United States',
            'Louisville, KY, United States',
            'Edison, NJ, United States',
            'Secaucus, NJ, United States',
            'Parsippany, NJ, United States'
        ];
        // Use a simple deterministic pick based on origin/dest
        if (dest.includes('NJ') || dest.includes('Jersey')) {
            return 'Edison, NJ, United States';
        }
        return hubs[0]; // default to Memphis
    }
}