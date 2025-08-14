import { LightningElement, api } from 'lwc';

export default class Hot_commonTableRequests extends LightningElement {
    @api records = [];
    @api allRecords = [];
    @api columns = [];
    @api labelMap = {};
    @api ariaLabel;
    @api loading = false;

    recordMap = {};

    get recordsToShow() {
        const processed = [];
        this.recordMap = {};

        if (Array.isArray(this.records)) {
            for (let record of this.records) {
                let fields = this.columns.map((col) => {
                    const rawValue = record[col.fieldName];
                    const mapping = this.labelMap[col.fieldName]?.[rawValue];
                    return {
                        name: col.fieldName,
                        label: col.label,
                        value: rawValue,
                        displayLabel: mapping?.label ?? rawValue ?? '',
                        cssClass: mapping?.cssClass ?? ''
                    };
                });

                processed.push({
                    id: record.Id,
                    original: record,
                    fields
                });

                this.recordMap[record.Id] = record;
            }
        }

        return processed;
    }

    get hasData() {
        return this.recordsToShow.length > 0;
    }

    get hasAnyRecords() {
        return Array.isArray(this.allRecords) && this.allRecords.length > 0;
    }

    get emptyMessage() {
        if (!this.hasAnyRecords) {
            return 'Du har ingen bestillinger. Når du sender inn en ny bestilling vil den vises her.';
        }
        return 'Du har ingen bestillinger i fremtiden. Du kan endre filteret for å se tidligere bestillinger.';
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
        }
    }

    handleRowKeydown(event) {
        if (event.key === 'Enter') {
            this.handleRowClick(event);
        }
    }
}
