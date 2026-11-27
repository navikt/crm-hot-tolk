export const getRecord = jest.fn();
export const getRecordCreateDefaults = jest.fn();
export const updateRecord = jest.fn().mockResolvedValue({});
export const createRecord = jest.fn().mockResolvedValue({});
export const deleteRecord = jest.fn().mockResolvedValue();
export const generateRecordInputForCreate = jest.fn();
export const generateRecordInputForUpdate = jest.fn();
export const createRecordInputFilteredByEditedFields = jest.fn();
export const getRecordInput = jest.fn();
export const refresh = jest.fn().mockResolvedValue();
export const getRecordUi = jest.fn();
export const notifyRecordUpdateAvailable = jest.fn(() => Promise.resolve());

export const getFieldValue = jest.fn((record, field) => {
    const unqualifiedField = splitQualifiedFieldApiName(getFieldApiName(field))[1];
    const fields = unqualifiedField.split('.');
    let currentRecord = record;
    while (fields.length > 0 && currentRecord && currentRecord.fields) {
        const fieldName = fields.shift();
        const fieldValue = currentRecord.fields[fieldName];
        if (fieldValue === undefined) {
            return undefined;
        }
        currentRecord = fieldValue.value;
    }
    return currentRecord;
});

export const getFieldDisplayValue = jest.fn((record, field) => {
    const unqualifiedField = splitQualifiedFieldApiName(getFieldApiName(field))[1];
    const fields = unqualifiedField.split('.');
    let currentRecord = record;
    while (currentRecord && currentRecord.fields) {
        const fieldName = fields.shift();
        const fieldValue = currentRecord.fields[fieldName];
        if (fieldValue === undefined) {
            return undefined;
        }
        if (fields.length > 0) {
            currentRecord = fieldValue.value;
        } else {
            return fieldValue.displayValue;
        }
    }
    return currentRecord;
});

function getFieldApiName(value) {
    if (typeof value === 'string') {
        return value;
    }
    if (value && typeof value.objectApiName === 'string' && typeof value.fieldApiName === 'string') {
        return `${value.objectApiName}.${value.fieldApiName}`;
    }
    throw new TypeError('Value is not a string or FieldId.');
}

function splitQualifiedFieldApiName(fieldApiName) {
    const separatorIndex = fieldApiName.indexOf('.');
    if (separatorIndex < 1) {
        throw new TypeError('Value does not include an object API name.');
    }
    return [fieldApiName.substring(0, separatorIndex), fieldApiName.substring(separatorIndex + 1)];
}
