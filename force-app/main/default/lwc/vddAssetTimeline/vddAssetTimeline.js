import { LightningElement, api, wire } from 'lwc';
import getTimelineData from '@salesforce/apex/VDD_TimelineCtrl.getTimelineData';

export default class VddAssetTimeline extends LightningElement {
    @api recordId;
    stages = [];
    error;
    isLoading = true;

    @wire(getTimelineData, { recordId: '$recordId' })
    wiredTimeline({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.stages = data.map((stage, index) => ({
                ...stage,
                key: `stage-${index}`,
                isCompleted: stage.status === 'completed',
                isCurrent: stage.status === 'current',
                isUpcoming: stage.status === 'upcoming',
                stepClass: this.getStepClass(stage.status),
                iconClass: this.getIconClass(stage.status, stage.stage),
                connectorClass: this.getConnectorClass(stage.status, index, data.length),
                formattedTimestamp: stage.timestamp ? this.formatDate(stage.timestamp) : '',
                showPulse: stage.stage === 'Operational' && stage.status === 'current',
                stageIcon: this.getStageEmoji(stage.stage)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error';
            this.stages = [];
        }
    }

    getStepClass(status) {
        const base = 'timeline-step';
        if (status === 'completed') return `${base} step-completed`;
        if (status === 'current') return `${base} step-current`;
        return `${base} step-upcoming`;
    }

    getIconClass(status, stage) {
        const base = 'step-icon';
        if (status === 'completed') return `${base} icon-completed`;
        if (status === 'current') {
            return stage === 'Operational' ? `${base} icon-operational` : `${base} icon-current`;
        }
        return `${base} icon-upcoming`;
    }

    getConnectorClass(status, index, total) {
        if (index >= total - 1) return 'connector connector-hidden';
        if (status === 'completed') return 'connector connector-completed';
        return 'connector connector-upcoming';
    }

    getStageEmoji(stage) {
        const emojis = {
            'Ordered': '🛒',
            'Shipped': '🚚',
            'Delivered': '📦',
            'Installed': '🔧',
            'Operational': '📡'
        };
        return emojis[stage] || '●';
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        try {
            const d = new Date(dateStr);
            return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        } catch (e) {
            return '';
        }
    }

    get hasStages() {
        return this.stages && this.stages.length > 0;
    }
}