import { LightningElement, api } from 'lwc';

export default class Hot_commonTableRequests extends LightningElement {
    @api records = [];
    @api columns = [];
    @api labelMap = {}; // used for mapping status or other fields to label + css class

    get isMobile() {
        return window.screen.width < 576;
    }

    getFormattedValue(field, value) {
        const mapEntry = this.labelMap[field]?.[value];
        return mapEntry ? { label: mapEntry.label, cssClass: mapEntry.cssClass } : { label: value, cssClass: '' };
    }

    get hasData() {
        return Array.isArray(this.records) && this.records.length > 0;
    }

    get displayRows() {
        if (!this.hasData || !Array.isArray(this.columns)) return [];

        return this.records.map((record, rowIndex) => {
            const cells = this.columns.map((col, colIndex) => {
                const value = record[col.fieldName] ?? '';
                const fieldMapping = this.getFormattedValue(col.fieldName, value);

                return {
                    key: `${rowIndex}-${col.fieldName}`,
                    value,
                    label: col.label,
                    isStatus: !!this.labelMap[col.fieldName],
                    statusLabel: fieldMapping.label,
                    fullStatusClass: fieldMapping.cssClass,
                    cellClass: colIndex === 0 ? 'first-column date-cell' : '',
                    desktopStatusClass: fieldMapping.cssClass ? `desktop-status-label ${fieldMapping.cssClass}` : ''
                };
            });

            const statusCell = cells.find((c) => c.isStatus);
            const mobileStatusClass = `mobile-status-label ${statusCell?.fullStatusClass || ''}`;

            return {
                key: record.Id || `row-${rowIndex}`,
                cells,
                original: record,
                statusLabel: statusCell?.statusLabel,
                mobileStatusClass
            };
        });
    }

    handleRowClick(event) {
        const key = event.currentTarget.dataset.key;
        const row = this.displayRows.find((row) => row.key === key);
        if (row?.original) {
            this.dispatchEvent(
                new CustomEvent('rowclick', {
                    detail: row.original,
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
