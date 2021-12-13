import { LightningElement, track, api } from 'lwc';

export default class Table extends LightningElement {
    @api columns;
    @api records;

    get recordsToShow() {
        let records = [];
        for (let record of this.records) {
            let fields = [];
            for (let column of this.columns) {
                let field = {
                    name: column.name,
                    value: record[column.name],
                    svg: column.svg
                };
                fields.push(field);
            }
            records.push({
                id: record.Id,
                fields: fields
            });
        }
        return records;
    }

    handleOnRowClick(event) {
        const eventToSend = new CustomEvent('rowclick', { detail: event.currentTarget.dataset.id });
        this.dispatchEvent(eventToSend);
    }
}
