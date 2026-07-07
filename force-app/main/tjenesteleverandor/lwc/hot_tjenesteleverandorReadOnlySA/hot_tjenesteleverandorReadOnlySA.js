import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LANG from '@salesforce/i18n/lang';

import SUBJECT_FIELD from '@salesforce/schema/ServiceAppointment.Subject';
import ADDRESS_FORMATED_FIELD from '@salesforce/schema/ServiceAppointment.HOT_AddressFormated__c';

const FIELDS = [SUBJECT_FIELD, ADDRESS_FORMATED_FIELD];

export default class HOT_TjenesteleverandorSAReadOnly extends LightningElement {
    @api recordId;
    lang = LANG;

    informationBannerTitle = 'Status på oppdraget er "Overført til tjenesteleverandør"';
    informationBannerContent = 'Formidler kan ikke redigere oppdraget når denne statusen er satt.';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get subjectValue() {
        return getFieldValue(this.record.data, SUBJECT_FIELD);
    }

    get subjectLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Tema' : 'Subject';
    }

    get addressFormattedValue() {
        return getFieldValue(this.record.data, ADDRESS_FORMATED_FIELD);
    }

    get addressFormattedLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Oppmøteadresse' : 'Address';
    }
}
