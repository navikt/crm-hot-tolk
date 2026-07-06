import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LANG from '@salesforce/i18n/lang';
import ACCOUNT_FIELD from '@salesforce/schema/ServiceAppointment.AccountId';
import CONTACT_FIELD from '@salesforce/schema/ServiceAppointment.ContactId';
import WORK_TYPE_FIELD from '@salesforce/schema/ServiceAppointment.WorkTypeId';

const FIELDS = [ACCOUNT_FIELD, CONTACT_FIELD, WORK_TYPE_FIELD];

export default class HOT_TjenesteleverandorSAReadOnly extends LightningElement {
    @api recordId;
    lang = LANG;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get accountId() {
        return getFieldValue(this.record.data, ACCOUNT_FIELD);
    }

    get accountLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Konto' : 'Account';
    }

    get contactId() {
        return getFieldValue(this.record.data, CONTACT_FIELD);
    }

    get contactLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Kontakt' : 'Contact';
    }

    get workTypeId() {
        return getFieldValue(this.record.data, WORK_TYPE_FIELD);
    }

    get workTypeLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Tolkemetode' : 'Work Type';
    }
}
