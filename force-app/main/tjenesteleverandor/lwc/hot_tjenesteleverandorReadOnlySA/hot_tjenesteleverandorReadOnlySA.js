import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import LANG from '@salesforce/i18n/lang';

import SUBJECT_FIELD from '@salesforce/schema/ServiceAppointment.Subject';
import ADDRESS_FORMATED_FIELD from '@salesforce/schema/ServiceAppointment.HOT_AddressFormated__c';

const FIELDS = [SUBJECT_FIELD, ADDRESS_FORMATED_FIELD];

export default class HOT_TjenesteleverandorSAReadOnly extends LightningElement {
    @api recordId;
    lang = LANG;

    informationBannerTitle = 'Status på oppdraget er "Overført til tjenesteleverandør"';
    informationBannerContent =
        'Nav-formidler kan ikke lenger redigere detaljer på oppdraget når det er overført til tjenesteleverandør.';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'ServiceResources',
        fields: ['AssignedResource.Id', 'AssignedResource.ServiceResource.Name'],
        pageSize: 1999,
        sortBy: ['AssignedResource.ServiceResource.Name']
    })
    assignedResourcesResult;

    get assignedResources() {
        return this.assignedResourcesResult?.data?.records.map((record) => ({
            id: record.id,
            name: this.formatResourceName(getFieldValue(record, 'AssignedResource.ServiceResource.Name'))
        }));
    }

    formatResourceName(name) {
        return name
            ?.toLocaleLowerCase(this.lang)
            .replace(/(^|[\s'\u2019-])\p{L}/gu, (value) => value.toLocaleUpperCase(this.lang));
    }

    get hasAssignedResources() {
        return this.assignedResources?.length > 0;
    }

    get assignedResourcesError() {
        return this.assignedResourcesResult?.error;
    }

    get hasMoreAssignedResources() {
        return Boolean(this.assignedResourcesResult?.data?.nextPageToken);
    }

    get isLoadingAssignedResources() {
        return !this.assignedResources && !this.assignedResourcesError;
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
}
