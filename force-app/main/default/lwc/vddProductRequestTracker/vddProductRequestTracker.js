import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getShipmentForProductRequest from '@salesforce/apex/VDD_ShipmentLookupCtrl.getShipmentForProductRequest';
import confirmDelivery from '@salesforce/apex/VDD_ShipmentLookupCtrl.confirmDelivery';

const MILESTONES = [
    { key: 'ordered',      label: 'Order Placed' },
    { key: 'shipped',      label: 'Shipped' },
    { key: 'in_transit',   label: 'In Transit' },
    { key: 'out_delivery', label: 'Out for Delivery' },
    { key: 'delivered',    label: 'Delivered' }
];

export default class VddProductRequestTracker extends NavigationMixin(LightningElement) {
    @api recordId;
    shipmentData;
    error;
    noShipment = false;
    isConfirming = false;
    deliveryMessage = '';
    _wiredResult;

    @wire(getShipmentForProductRequest, { productRequestId: '$recordId' })
    wiredShipment(result) {
        this._wiredResult = result;
        const { error, data } = result;
        if (data) {
            this.shipmentData = data;
            this.noShipment = false;
            this.error = undefined;
        } else if (data === null) {
            this.noShipment = true;
            this.shipmentData = undefined;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.shipmentData = undefined;
        }
    }

    get isLoading() {
        return !this.shipmentData && !this.error && !this.noShipment;
    }

    get hasShipment() {
        return !!this.shipmentData;
    }

    get status() {
        return this.shipmentData ? this.shipmentData.status : '';
    }

    get shipmentNumber() {
        return this.shipmentData ? this.shipmentData.shipmentNumber : '';
    }

    get shipToName() {
        return this.shipmentData ? this.shipmentData.shipToName : '';
    }

    get trackingNumber() {
        return this.shipmentData ? this.shipmentData.trackingNumber : '';
    }

    get trackingUrl() {
        return this.shipmentData ? this.shipmentData.trackingUrl : '';
    }

    get carrier() {
        return this.shipmentData ? this.shipmentData.provider : '';
    }

    get expectedDelivery() {
        return this.shipmentData && this.shipmentData.expectedDeliveryDate
            ? this.shipmentData.expectedDeliveryDate : '—';
    }

    get actualDelivery() {
        return this.shipmentData ? this.shipmentData.actualDeliveryDate : null;
    }

    get originAddress() {
        return this.shipmentData ? this.shipmentData.shipFromAddress : '';
    }

    get destinationAddress() {
        return this.shipmentData ? this.shipmentData.shipToAddress : '';
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

    navigateToShipment() {
        if (this.shipmentData && this.shipmentData.shipmentId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.shipmentData.shipmentId,
                    objectApiName: 'Shipment',
                    actionName: 'view'
                }
            });
        }
    }

    get showConfirmButton() {
        return this.hasShipment && !this.isDelivered && !this.deliveryMessage;
    }

    handleConfirmDelivery() {
        if (!this.shipmentData || !this.shipmentData.shipmentId || this.isConfirming) {
            return;
        }
        this.isConfirming = true;
        this.deliveryMessage = '';

        confirmDelivery({ shipmentId: this.shipmentData.shipmentId })
            .then((message) => {
                this.deliveryMessage = message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Delivery Confirmed',
                        message: message,
                        variant: 'success'
                    })
                );
                return refreshApex(this._wiredResult);
            })
            .catch((error) => {
                const msg = error.body ? error.body.message : error.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: msg || 'Failed to confirm delivery.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isConfirming = false;
            });
    }
}