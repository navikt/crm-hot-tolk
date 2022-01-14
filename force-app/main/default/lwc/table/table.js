import { LightningElement, api } from 'lwc';

export default class Table extends LightningElement {
    @api columns;
    @api records;
    @api iconByValue;
    @api hideMobileHeader;

    recordMap = {};
    get recordsToShow() {
        let records = [];
        if (this.records !== undefined && this.records !== null) {
            for (let record of this.records) {
                let fields = [];
                for (let column of this.columns) {
                    let field = {
                        name: column.name
                    };
                    field.value = this.getValue(record, column);
                    if (column.svg !== undefined && this.iconByValue[record[column.name]] !== undefined) {
                        field.svg = this.iconByValue[record[column.name]];
                    }
                    fields.push(field);
                }
                records.push({
                    id: record.Id,
                    fields: fields
                });
                this.recordMap[record.Id] = record;
            }
        }
        return records;
    }

    getValue(record, column) {
        if (column.name === 'StartAndEndDate') {
            let startDate = this.setDateFormat(record.StartDate);
            let endDate = this.setDateFormat(record.EndDate);
            let startDateSplit = startDate.split(',');
            let endDateSplit = endDate.split(',');
            if (startDateSplit[0] === endDateSplit[0]) {
                return startDate + ' - ' + endDateSplit[1];
            }
            return startDate + ' - ' + endDate;
        }
        let value = record[column.name];
        return value;
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }

    handleOnRowClick(event) {
        const eventToSend = new CustomEvent('rowclick', { detail: this.recordMap[event.currentTarget.dataset.id] });
        this.dispatchEvent(eventToSend);
    }
}
