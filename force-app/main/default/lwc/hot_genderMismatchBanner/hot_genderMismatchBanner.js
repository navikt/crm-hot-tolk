import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

const PREFERRED_GENDER = 'ServiceAppointment.HOT_UserPreferredGender__c';
const SERVICE_RESOURCE = 'ServiceAppointment.HOT_ServiceResource__c';
const RESOURCE_GENDER = 'ServiceAppointment.HOT_ServiceResource__r.HOT_Gender__c';

export default class Hot_genderMismatchBanner extends LightningElement {
    @api recordId;

    record;
    dismissed = false;
    errorMessage;

    get preferredGender() {
        return getFieldValue(this.record, PREFERRED_GENDER);
    }

    get resourceGender() {
        return getFieldValue(this.record, RESOURCE_GENDER);
    }

    get dismissedKey() {
        const resourceId = getFieldValue(this.record, SERVICE_RESOURCE);
        return `genderMismatchBannerDismissed_${this.recordId}_${USER_ID}_${resourceId}_${this.preferredGender}_${this.resourceGender}`;
    }

    get showBanner() {
        return (
            this.record?.id === this.recordId &&
            !!this.preferredGender &&
            !!getFieldValue(this.record, SERVICE_RESOURCE) &&
            this.preferredGender !== this.resourceGender &&
            !this.dismissed
        );
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [PREFERRED_GENDER, SERVICE_RESOURCE, RESOURCE_GENDER]
    })
    wiredServiceAppointment({ data, error }) {
        this.record = data;
        this.errorMessage = undefined;
        this.dismissed = false;

        if (error) {
            this.errorMessage = 'Kunne ikke kontrollere om tolkens kjønn samsvarer med ønsket kjønn.';
            console.error('hot_genderMismatchBanner getRecord error', error);
            return;
        }
        if (!data) return;

        try {
            this.dismissed = window.localStorage.getItem(this.dismissedKey) === '1';
        } catch (error) {
            console.error('hot_genderMismatchBanner could not read dismissal', error);
        }
    }

    handleClose() {
        this.dismissed = true;
        try {
            window.localStorage.setItem(this.dismissedKey, '1');
        } catch (error) {
            console.error('hot_genderMismatchBanner could not remember dismissal', error);
        }
    }
}
