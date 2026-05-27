import { LightningElement, api, wire } from 'lwc';
import getHealthMetrics from '@salesforce/apex/VDD_HealthCtrl.getHealthMetrics';
import getThresholdStatus from '@salesforce/apex/VDD_HealthCtrl.getThresholdStatus';
import getAssetInfo from '@salesforce/apex/VDD_HealthCtrl.getAssetInfo';

export default class VddHealthDashboard extends LightningElement {
    @api recordId;

    metrics = {};
    monitors = [];
    assetInfo = {};
    error;
    isLoading = true;

    gaugeConfigs = [
        {
            key: 'GPS_Fix_Accuracy',
            label: 'GPS Accuracy',
            unit: 'm',
            min: 0,
            max: 25,
            greenMax: 5,
            amberMax: 15,
            invert: true // lower is better
        },
        {
            key: 'Cellular_Signal_Strength',
            label: 'Signal Strength',
            unit: 'dBm',
            min: -120,
            max: -50,
            greenMin: -85,
            amberMin: -100,
            invert: false // higher (less negative) is better
        },
        {
            key: 'Battery_Voltage',
            label: 'Battery Voltage',
            unit: 'V',
            min: 10,
            max: 16,
            greenMin: 12.4,
            greenMax: 14.7,
            amberMin: 11.8,
            invert: false
        }
    ];

    @wire(getHealthMetrics, { assetId: '$recordId' })
    wiredMetrics({ error, data }) {
        if (data) {
            this.metrics = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Error loading metrics';
        }
        this.checkLoading();
    }

    @wire(getThresholdStatus, { assetId: '$recordId' })
    wiredMonitors({ error, data }) {
        if (data) {
            this.monitors = data.map((m, i) => ({
                ...m,
                key: `monitor-${i}`,
                badgeClass: m.withinThreshold ? 'badge badge-ok' : 'badge badge-breach',
                statusIcon: m.withinThreshold ? '✓' : '⚠',
                statusLabel: m.withinThreshold ? 'Within Threshold' : 'Breached'
            }));
        }
        this.checkLoading();
    }

    @wire(getAssetInfo, { assetId: '$recordId' })
    wiredInfo({ error, data }) {
        if (data) {
            this.assetInfo = data;
        }
        this.checkLoading();
    }

    checkLoading() {
        // Simple loading check — stop loading once any wire returns
        this.isLoading = false;
    }

    get gauges() {
        return this.gaugeConfigs.map(config => {
            const rawValue = this.metrics[config.key];
            const value = rawValue ? parseFloat(rawValue) : null;
            const hasValue = value !== null && !isNaN(value);

            let status = 'unknown';
            let statusColor = '#706e6b';
            let displayValue = '--';

            if (hasValue) {
                displayValue = `${value} ${config.unit}`;
                status = this.getGaugeStatus(value, config);
                statusColor = this.getStatusColor(status);
            }

            const percentage = hasValue
                ? Math.min(100, Math.max(0, ((value - config.min) / (config.max - config.min)) * 100))
                : 0;

            return {
                ...config,
                value,
                displayValue,
                status,
                statusColor,
                percentage: config.invert ? (100 - percentage) : percentage,
                barStyle: `width: ${config.invert ? (100 - percentage) : percentage}%; background-color: ${statusColor};`,
                hasValue
            };
        });
    }

    getGaugeStatus(value, config) {
        if (config.key === 'GPS_Fix_Accuracy') {
            if (value <= config.greenMax) return 'good';
            if (value <= config.amberMax) return 'warning';
            return 'critical';
        }
        if (config.key === 'Cellular_Signal_Strength') {
            if (value >= config.greenMin) return 'good';
            if (value >= config.amberMin) return 'warning';
            return 'critical';
        }
        if (config.key === 'Battery_Voltage') {
            if (value >= config.greenMin && value <= config.greenMax) return 'good';
            if (value >= config.amberMin) return 'warning';
            return 'critical';
        }
        return 'unknown';
    }

    getStatusColor(status) {
        const colors = {
            good: '#04844b',
            warning: '#ff9a3c',
            critical: '#c23934',
            unknown: '#706e6b'
        };
        return colors[status] || colors.unknown;
    }

    get hasMetrics() {
        return Object.keys(this.metrics).length > 0;
    }

    get lastPingFormatted() {
        if (!this.metrics.Last_Ping_Time) return 'N/A';
        try {
            return new Date(this.metrics.Last_Ping_Time).toLocaleString();
        } catch (e) {
            return this.metrics.Last_Ping_Time;
        }
    }

    get pingRate() {
        return this.metrics.Ping_Rate_Seconds ? `${this.metrics.Ping_Rate_Seconds}s` : 'N/A';
    }

    get deviceESN() {
        return this.metrics.Device_ESN || this.assetInfo.deviceESN || 'N/A';
    }

    get overallStatus() {
        const statuses = this.gauges.map(g => g.status);
        if (statuses.includes('critical')) return { label: 'Critical', variant: 'error', icon: '🔴' };
        if (statuses.includes('warning')) return { label: 'Warning', variant: 'warning', icon: '🟡' };
        if (statuses.some(s => s === 'good')) return { label: 'Healthy', variant: 'success', icon: '🟢' };
        return { label: 'No Data', variant: 'neutral', icon: '⚪' };
    }

    get hasMonitors() {
        return this.monitors && this.monitors.length > 0;
    }
}