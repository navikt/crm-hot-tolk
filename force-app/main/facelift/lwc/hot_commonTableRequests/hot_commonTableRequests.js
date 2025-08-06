import { LightningElement, api } from 'lwc';

export default class Hot_commonTableRequests extends LightningElement {
    @api records = [];
    @api columns = [];
    @api labelMap = {}; // used for mapping status or other fields to label + css class
    @api ariaLabel;

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
                index: rowIndex,
                cells,
                original: record,
                statusLabel: statusCell?.statusLabel,
                mobileStatusClass
            };
        });
    }

    handleRowClick(event) {
        const index = event.currentTarget.dataset.index;
        if (index === undefined) {
            console.warn('Missing row index on click');
            return;
        }

        const record = this.records[index];
        if (record) {
            this.dispatchEvent(
                new CustomEvent('rowclick', {
                    detail: record,
                    bubbles: true,
                    composed: true
                })
            );
        } else {
            console.warn('No matching record at index:', index);
            console.log('Records:', this.records);
        }
    }

    handleRowKeydown(event) {
        if (event.key === 'Enter') {
            this.handleRowClick(event);
        }
    }
}
