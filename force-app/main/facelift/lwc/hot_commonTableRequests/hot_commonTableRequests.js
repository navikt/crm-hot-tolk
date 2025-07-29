import { LightningElement, api } from 'lwc';

export default class Hot_commonTableRequests extends LightningElement {
    @api records = [];
    @api columns = [];
    @api labelMap = {}; // used for mapping status or other fields to label + css class
    @api ariaLabel;

    recordMap = {};

    get isMobile() {
        return window.screen.width < 576;
    }

    get recordsToShow() {
        const processed = [];
        this.recordMap = {};

        if (Array.isArray(this.records)) {
            for (let record of this.records) {
                let fields = [];

                for (let column of this.columns) {
                    const fieldName = column.fieldName;
                    const rawValue = record[fieldName];
                    const mapping = this.labelMap[fieldName]?.[rawValue];

                    fields.push({
                        name: fieldName,
                        label: column.label,
                        value: rawValue,
                        displayLabel: mapping?.label ?? rawValue,
                        cssClass: mapping?.cssClass ?? '',
                        isStatus: !!mapping,
                        fullCssClass: mapping?.cssClass ? `desktop-status-label ${mapping.cssClass}` : ''
                    });
                }

                const statusField = fields.find((f) => f.isStatus);

                processed.push({
                    id: record.Id,
                    original: record,
                    fields,
                    statusLabel: statusField?.displayLabel,
                    mobileStatusClass: statusField ? `mobile-status-label ${statusField.cssClass}` : ''
                });

                this.recordMap[record.Id] = record;
            }
        }

        return processed;
    }

    get hasData() {
        return this.recordsToShow.length > 0;
    }

    handleRowClick(event) {
        const recordId = event.currentTarget.dataset.id;
        const record = this.recordMap[recordId];
        if (record) {
            this.dispatchEvent(
                new CustomEvent('rowclick', {
                    detail: record,
                    bubbles: true,
                    composed: true
                })
            );
        } else {
            console.warn('No matching record for row click:', recordId);
            console.log('Records:', this.records);
        }
    }

    handleRowKeydown(event) {
        if (event.key === 'Enter') {
            this.handleRowClick(event);
        }
    }
}
