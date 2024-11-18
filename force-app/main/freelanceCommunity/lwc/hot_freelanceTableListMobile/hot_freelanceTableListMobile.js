import { LightningElement, api } from 'lwc';

export default class Table extends LightningElement {
    @api columns;
    @api records;
    @api iconByValue;
    @api hideMobileHeader;
    @api checkbox = false;

    get mobileHeaderStyle() {
        return this.hideMobileHeader && window.screen.width < 576 ? 'position: absolute; left: -10000px;' : '';
    }

    recordMap = {};
    get recordsToShow() {
        let records = [];
        this.recordMap = {};
        if (this.records !== undefined && this.records !== null) {
            for (let record of this.records) {
                let fields = [];
                for (let column of this.columns) {
                    let field = {
                        name: column.name
                    };
                    field.value = record[column.name];
                    if (column.svg !== undefined && this.iconByValue[record[column.name]] !== undefined) {
                        field.svg = this.iconByValue[record[column.name]];
                    }
                    if (column.bold !== undefined) {
                        field.bold = column.bold;
                    }
                    if (column.label !== undefined) {
                        field.label = column.label;
                    }
                    fields.push(field);
                }
                records.push({
                    id: record.Id,
                    checked: this.checkedRows.includes(record.Id),
                    fields: fields
                });
                this.recordMap[record.Id] = record;
            }
        }
        return records;
    }

    handleOnRowClick(event) {
        const eventToSend = new CustomEvent('rowclick', { detail: this.recordMap[event.currentTarget.dataset.id] });
        this.dispatchEvent(eventToSend);
    }

    sendCheckedRows() {
        const eventToSend = new CustomEvent('checkedrows', {
            detail: { checkedRows: this.checkedRows }
        });
        this.dispatchEvent(eventToSend);
    }

    @api checkedRows = [];
    @api getCheckedRows() {
        return this.checkedRows;
    }

    @api unsetCheckboxes() {
        this.template.querySelectorAll('c-checkbox').forEach((element) => {
            element.clearCheckboxValue();
        });
        this.checkedRows = [];
    }

    handleSingleCheckboxClick() {
        let recordIdArray = this.resetRecordIdArray();
        this.template.querySelectorAll('c-checkbox').forEach((element, index) => {
            if (element.getValue()) {
                recordIdArray[index - 1].checked = true; // Index-1 to account for the first checkbox in header
            }
        });
        recordIdArray.forEach((element) => {
            if (element.checked) {
                this.checkedRows.push(element.id);
            }
        });
        this.sendCheckedRows();
    }

    handleAllCheckboxesClick(event) {
        let recordIdArray = this.resetRecordIdArray();
        this.template.querySelectorAll('c-checkbox').forEach((element) => {
            element.setCheckboxValue(event.detail);
        });
        let tempArr = recordIdArray.map((x) => ({ ...x, checked: event.detail }));
        tempArr.forEach((element) => {
            if (element.checked) {
                this.checkedRows.push(element.id);
            }
        });
        this.sendCheckedRows();
    }

    resetRecordIdArray() {
        this.checkedRows = [];
        let recordArray = Object.entries(this.recordMap);
        let recordIdArray = [];
        recordArray.forEach((element) => {
            recordIdArray.push({ id: element[0], checked: false });
        });
        return recordIdArray;
    }
}
