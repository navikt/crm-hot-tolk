import { LightningElement, api } from 'lwc';

export default class hot_recordDetails extends LightningElement {
    @api record;
}

export function formatRecord(record, fieldLabels) {
    let fields = [];
    for (let field in record) {
        if (fieldLabels[field]) {
            if (fieldLabels[field].type === 'string') {
                fields.push({ name: field, label: fieldLabels[field].label, value: record[field] });
            } else if (fieldLabels[field].type === 'date') {
                fields.push({ name: field, label: fieldLabels[field].label, value: formatDate(record[field]) });
            } else if (fieldLabels[field].type === 'datetime') {
                fields.push({ name: field, label: fieldLabels[field].label, value: formatDatetime(record[field]) });
            }
        }
    }
    return fields;
}

function formatDatetime(datetimeString) {
    console.log(datetimeString);
    let sub = datetimeString.substr(0, datetimeString.length - 1);
    let datetime = new Date(sub);
    let year = datetime.getFullYear().toString();
    let month = (datetime.getMonth() + 1).toString();
    let day = datetime.getDate();
    let hour = datetime.getHours() - datetime.getTimezoneOffset() / 60;
    if (hour >= 24) {
        hour = hour - 24;
        day = day + 1;
    }
    day = day.toString();
    hour = hour.toString();
    hour = hour.length === 1 ? '0' + hour : hour;
    let minute = datetime.getMinutes().toString();
    minute = minute.length === 1 ? '0' + minute : minute;
    let formated = day + '.' + month + '.' + year + ' ' + hour + ':' + minute;
    return formated;
}

function formatDate(dateString) {
    let sub = dateString.substr(0, dateString.length - 1);
    let datetime = new Date(sub);
    let year = datetime.getFullYear().toString();
    let month = (datetime.getMonth() + 1).toString();
    let day = datetime.getDate().toString();
    let formated = day + '.' + month + '.' + year;
    return formated;
}
