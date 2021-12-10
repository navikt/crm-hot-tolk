import { LightningElement, api, track } from 'lwc';

export default class RecordList extends LightningElement {
    @api columns;
    @track recordsToShow;

    @api
    showRecords(records) {
        let recordsToShow = [];
        for (let record of records) {
            let recordToShow = [];
            for (let column of this.columns) {
                let field = {
                    name: column.name,
                    value: record[column.name]
                };
                recordToShow.push(field);
            }
            recordsToShow.push({
                id: record.Id,
                record: recordToShow
            });
        }
        this.recordsToShow = recordsToShow;
    }

    handleOnRowClick(result) {
        const eventToSend = new CustomEvent('rowclick', { detail: result.detail });
        this.dispatchEvent(eventToSend);
    }
}
