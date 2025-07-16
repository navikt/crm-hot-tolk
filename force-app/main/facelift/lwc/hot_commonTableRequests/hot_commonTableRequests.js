import { LightningElement, api } from 'lwc';

export default class Hot_commonTableRequests extends LightningElement {
    @api columns = [];
    @api records = [];
    @api ariaLabel = 'Dynamisk tabell';

    statusMap = {
        Completed: { label: 'Du har fått tolk', cssClass: 'label-green' },
        New: { label: 'Åpen', cssClass: 'label-gray' },
        Canceled: { label: 'Avlyst', cssClass: 'label-red' },
        Dispatched: { label: 'Under Behandling', cssClass: 'label-orange' },
        Scheduled: { label: 'Under Behandling', cssClass: 'label-orange' }
    };

    get hasData() {
        return Array.isArray(this.records) && this.records.length > 0;
    }

    get displayRows() {
        if (!this.hasData || !Array.isArray(this.columns)) return [];

        return this.records.map((record, rowIndex) => {
            const cells = this.columns.map((col, colIndex) => {
                const value = record[col.fieldName] ?? '';
                const isStatus = col.fieldName === 'Status';
                let statusLabel = '';
                let cssClass = '';

                if (isStatus) {
                    const status = this.statusMap[value] || {};
                    statusLabel = status.label || value;
                    cssClass = status.cssClass || '';
                }

                return {
                    key: `${rowIndex}-${col.fieldName}`,
                    value,
                    label: col.label,
                    isStatus,
                    statusLabel,
                    fullStatusClass: cssClass,
                    cellClass: colIndex === 0 ? 'first-column date-cell' : '',
                    desktopStatusClass: isStatus ? `desktop-status-label ${cssClass}` : ''
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
