import { LightningElement, api } from 'lwc';

export default class Hot_commonTableRequests extends LightningElement {
    @api records = [];
    @api columns = [];
    @api labelMap = {};
    @api ariaLabel;

    recordMap = {};

    get recordsToShow() {
        const processed = [];
        this.recordMap = {};

        const targetFieldName =
            (Array.isArray(this.columns)
                ? this.columns.find((c) => (c.label || '').toLowerCase() === 'tema')?.fieldName
                : undefined) ?? 'StartAndEndDate';

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

                const targetField = fields.find((f) => f.name === targetFieldName);
                const ariaLabelRow = (targetField?.displayLabel ?? targetField?.value ?? '').toString();

                processed.push({
                    id: record.Id,
                    original: record,
                    fields,
                    ariaLabelRow
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
        }
    }

    handleRowKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleRowClick(event);
        }
    }
}
