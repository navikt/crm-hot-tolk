import { LightningElement, api } from 'lwc';

export default class Table extends LightningElement {
    @api columns;
    @api records;

    recordMap = {};

    get recordsToShow() {
        let records = [];
        if (this.records !== undefined && this.records !== null) {
            console.log(this.records);
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
                this.recordMap[record.Id] = record;
            }
        }
        return records;
    }

    handleOnRowClick(event) {
        console.log(event.currentTarget.dataset.id);
        console.log(this.recordMap[event.currentTarget.dataset.id]);
        console.log(this.recordMap);
        const eventToSend = new CustomEvent('rowclick', { detail: this.recordMap[event.currentTarget.dataset.id] });
        this.dispatchEvent(eventToSend);
    }
}
