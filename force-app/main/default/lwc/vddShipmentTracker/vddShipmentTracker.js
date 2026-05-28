import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';

import STATUS_FIELD from '@salesforce/schema/Shipment.Status';
import SHIP_TO_NAME from '@salesforce/schema/Shipment.ShipToName';
import TRACKING_NUMBER from '@salesforce/schema/Shipment.TrackingNumber';
import TRACKING_URL from '@salesforce/schema/Shipment.TrackingUrl';
import PROVIDER from '@salesforce/schema/Shipment.Provider';
import EXPECTED_DATE from '@salesforce/schema/Shipment.ExpectedDeliveryDate';
import ACTUAL_DATE from '@salesforce/schema/Shipment.ActualDeliveryDate';
import SHIP_FROM_STREET from '@salesforce/schema/Shipment.ShipFromStreet';
import SHIP_FROM_CITY from '@salesforce/schema/Shipment.ShipFromCity';
import SHIP_FROM_STATE from '@salesforce/schema/Shipment.ShipFromState';
import SHIP_TO_STREET from '@salesforce/schema/Shipment.ShipToStreet';
import SHIP_TO_CITY from '@salesforce/schema/Shipment.ShipToCity';
import SHIP_TO_STATE from '@salesforce/schema/Shipment.ShipToState';
import SHIPMENT_NAME from '@salesforce/schema/Shipment.ShipmentNumber';

const FIELDS = [
    STATUS_FIELD, SHIP_TO_NAME, TRACKING_NUMBER, TRACKING_URL, PROVIDER,
    EXPECTED_DATE, ACTUAL_DATE, SHIP_FROM_STREET, SHIP_FROM_CITY,
    SHIP_FROM_STATE, SHIP_TO_STREET, SHIP_TO_CITY, SHIP_TO_STATE, SHIPMENT_NAME
];

const MILESTONES = [
    { key: 'ordered',       label: 'Order Placed',      icon: 'standard:orders',            statusMatch: [] },
    { key: 'shipped',       label: 'Shipped',           icon: 'standard:shipment',          statusMatch: ['Shipped'] },
    { key: 'in_transit',    label: 'In Transit',        icon: 'standard:location',          statusMatch: ['In Transit'] },
    { key: 'out_delivery',  label: 'Out for Delivery',  icon: 'standard:service_territory', statusMatch: ['Out for Delivery'] },
    { key: 'delivered',     label: 'Delivered',          icon: 'standard:task2',             statusMatch: ['Delivered'] }
];

const POLL_INTERVAL_MS = 3000;

export default class VddShipmentTracker extends LightningElement {
    @api recordId;
    shipment;
    error;
    _wiredResult;
    _pollingTimer;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredShipment(result) {
        this._wiredResult = result;
        const { error, data } = result;
        if (data) {
            this.shipment = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.shipment = undefined;
        }
    }

    connectedCallback() {
        this._startPolling();
    }

    disconnectedCallback() {
        this._stopPolling();
    }

    /**
     * Poll every 3 seconds to detect record changes.
     * getRecordNotifyChange tells Lightning Data Service
     * to re-fetch the record, which triggers the wire adapter.
     */
    _startPolling() {
        if (this._pollingTimer) return;
        this._pollingTimer = setInterval(() => {
            if (this.recordId) {
                getRecordNotifyChange([{ recordId: this.recordId }]);
            }
        }, POLL_INTERVAL_MS);
    }

    _stopPolling() {
        if (this._pollingTimer) {
            clearInterval(this._pollingTimer);
            this._pollingTimer = undefined;
        }
    }

    get isLoading() {
        return !this.shipment && !this.error;
    }

    get status() {
        return this.shipment ? getFieldValue(this.shipment, STATUS_FIELD) : '';
    }

    get shipmentNumber() {
        return this.shipment ? getFieldValue(this.shipment, SHIPMENT_NAME) : '';
    }

    get shipToName() {
        return this.shipment ? getFieldValue(this.shipment, SHIP_TO_NAME) : '';
    }

    get trackingNumber() {
        return this.shipment ? getFieldValue(this.shipment, TRACKING_NUMBER) : '';
    }

    get trackingUrl() {
        return this.shipment ? getFieldValue(this.shipment, TRACKING_URL) : '';
    }

    get carrier() {
        return this.shipment ? getFieldValue(this.shipment, PROVIDER) : '';
    }

    get expectedDelivery() {
        const val = this.shipment ? getFieldValue(this.shipment, EXPECTED_DATE) : null;
        return val ? new Date(val).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }) : '—';
    }

    get actualDelivery() {
        const val = this.shipment ? getFieldValue(this.shipment, ACTUAL_DATE) : null;
        return val ? new Date(val).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }) : null;
    }

    get originAddress() {
        if (!this.shipment) return '';
        const street = getFieldValue(this.shipment, SHIP_FROM_STREET) || '';
        const city = getFieldValue(this.shipment, SHIP_FROM_CITY) || '';
        const state = getFieldValue(this.shipment, SHIP_FROM_STATE) || '';
        return [street, city, state].filter(Boolean).join(', ');
    }

    get destinationAddress() {
        if (!this.shipment) return '';
        const street = getFieldValue(this.shipment, SHIP_TO_STREET) || '';
        const city = getFieldValue(this.shipment, SHIP_TO_CITY) || '';
        const state = getFieldValue(this.shipment, SHIP_TO_STATE) || '';
        return [street, city, state].filter(Boolean).join(', ');
    }

    get currentStepIndex() {
        const st = this.status;
        if (!st) return 0;
        if (st === 'Delivered') return 4;
        if (st === 'Out for Delivery') return 3;
        if (st === 'In Transit') return 2;
        if (st === 'Shipped') return 1;
        return 0;
    }

    get milestones() {
        const currentIdx = this.currentStepIndex;
        return MILESTONES.map((m, i) => {
            const isCompleted = i < currentIdx;
            const isCurrent = i === currentIdx;
            const isPending = i > currentIdx;
            return {
                ...m,
                isCompleted,
                isCurrent,
                isPending,
                stepClass: `tracker-step ${isCompleted ? 'completed' : ''} ${isCurrent ? 'current' : ''} ${isPending ? 'pending' : ''}`,
                dotClass: `step-dot ${isCompleted ? 'completed' : ''} ${isCurrent ? 'current' : ''}`,
                labelClass: `step-label ${isCurrent ? 'current' : ''} ${isCompleted ? 'completed' : ''}`
            };
        });
    }

    get progressWidth() {
        const idx = this.currentStepIndex;
        const pct = (idx / (MILESTONES.length - 1)) * 100;
        return `width: ${pct}%`;
    }

    get isDelivered() {
        return this.status === 'Delivered';
    }

    get statusBadgeClass() {
        const st = this.status;
        if (st === 'Delivered') return 'status-badge delivered';
        if (st === 'In Transit') return 'status-badge in-transit';
        return 'status-badge default';
    }

    get truckPosition() {
        const idx = this.currentStepIndex;
        const pct = (idx / (MILESTONES.length - 1)) * 100;
        return `left: ${pct}%`;
    }

    get showTruck() {
        return !this.isDelivered;
    }
}
