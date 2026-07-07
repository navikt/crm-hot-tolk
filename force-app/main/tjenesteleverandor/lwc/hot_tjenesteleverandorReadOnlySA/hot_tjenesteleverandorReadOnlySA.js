import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import LANG from '@salesforce/i18n/lang';

import PARENT_RECORD_FIELD from '@salesforce/schema/ServiceAppointment.ParentRecordId';
import SUBJECT_FIELD from '@salesforce/schema/ServiceAppointment.Subject';
import OWNER_FIELD from '@salesforce/schema/ServiceAppointment.OwnerId';
import SERVICE_TERRITORY_FIELD from '@salesforce/schema/ServiceAppointment.ServiceTerritoryId';
import ADDRESS_FORMATED_FIELD from '@salesforce/schema/ServiceAppointment.HOT_AddressFormated__c';
import CREATED_BY_FIELD from '@salesforce/schema/ServiceAppointment.CreatedById';
import LAST_MODIFIED_BY_FIELD from '@salesforce/schema/ServiceAppointment.LastModifiedById';
import STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
import TJENESTELEVERANDOR_STATUS_FIELD from '@salesforce/schema/ServiceAppointment.HOT_TjenesteleverandorStatus__c';

const FIELDS = [
    SUBJECT_FIELD,
    PARENT_RECORD_FIELD,
    ADDRESS_FORMATED_FIELD,
    CREATED_BY_FIELD,
    LAST_MODIFIED_BY_FIELD,
    STATUS_FIELD,
    TJENESTELEVERANDOR_STATUS_FIELD
];

export default class HOT_TjenesteleverandorSAReadOnly extends LightningElement {
    @api recordId;
    lang = LANG;

    informationBannerTitle = 'Status på oppdraget er "Overført til tjenesteleverandør"';
    informationBannerContent = 'Formidler kan ikke redigere oppdraget når denne statusen er satt.';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get parentRecordId() {
        return getFieldValue(this.record.data, PARENT_RECORD_FIELD);
    }

    get parentRecordLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Overordnet post' : 'Parent Record';
    }

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

    get createdById() {
        return getFieldValue(this.record.data, CREATED_BY_FIELD);
    }

    get lastModifiedById() {
        return getFieldValue(this.record.data, LAST_MODIFIED_BY_FIELD);
    }

    get createdByLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Opprettet av' : 'Created By';
    }

    get lastModifiedByLabel() {
        return this.lang && this.lang.toLowerCase().startsWith('no') ? 'Sist endret av' : 'Last Modified By';
    }

    get statusValue() {
        return getFieldValue(this.record.data, STATUS_FIELD);
    }

    get showTjenesteleverandorStatus() {
        const status = (this.statusValue || '').trim().toLowerCase();
        return status !== 'none' && status !== '';
    }
}
