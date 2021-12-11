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
        let rows = this.template.querySelectorAll('tr');
        rows.forEach((element) => {
            console.log(element.id);
        });

        const eventToSend = new CustomEvent('rowclick', { detail: rows[1].id.split('-')[0] });
        this.dispatchEvent(eventToSend);
    }
}
