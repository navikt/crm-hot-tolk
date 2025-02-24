export function formatDatetime(initialDatetime) {
    if (initialDatetime === undefined) {
        return null;
    }
    let datetime = new Date(initialDatetime);
    return (
        datetime.toLocaleDateString('nb-NO', { timeZone: 'Europe/Oslo' }) +
        ', ' +
        datetime.toLocaleTimeString('nb-NO', { hour: '2-digit', minute: '2-digit', timeZone: 'Europe/Oslo' })
    );
}

export function formatDate(initialDate) {
    if (initialDate === undefined) {
        return null;
    }
    let date = new Date(initialDate);
    return date.toLocaleDateString('nb-NO', { timeZone: 'Europe/Oslo' });
}

export function formatDatetimeinterval(initialStart, initialEnd) {
    if (initialStart === undefined || initialEnd === undefined) {
        return null;
    }
    let start = new Date(initialStart);
    let end = new Date(initialEnd);
    return (
        start.toLocaleDateString('nb-NO', { timeZone: 'Europe/Oslo' }) +
        ', ' +
        start.toLocaleTimeString('nb-NO', { hour: '2-digit', minute: '2-digit', timeZone: 'Europe/Oslo' }) +
        ' - ' +
        end.toLocaleTimeString('nb-NO', { hour: '2-digit', minute: '2-digit', timeZone: 'Europe/Oslo' })
    );
}

export function formatRecords(records, fields) {
    for (let record of records) {
        formatRecord(record, fields);
    }
    return records;
}

export function formatRecord(record, fields) {
    for (let field of fields) {
        let fieldname = field.newName === undefined ? field.name : field.newName;
        if (field.type == 'datetime') {
            record[fieldname] = formatDatetime(record[field.name]);
        } else if (field.type == 'date') {
            record[fieldname] = formatDate(record[field.name]);
        } else if (field.type == 'datetimeinterval') {
            record[fieldname] = formatDatetimeinterval(record[field.start], record[field.end]);
        }
    }
    return record;
}
