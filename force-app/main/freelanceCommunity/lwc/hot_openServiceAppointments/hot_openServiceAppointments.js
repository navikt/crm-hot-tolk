import { LightningElement, wire, track } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
//import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
//import { openServiceAppointmentFieldLabels } from 'c/hot_fieldLabels';
//import { formatRecord } from 'c/hot_recordDetails';

export default class Hot_openServiceAppointments extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    @track serviceResource;
    @track serviceResourceId;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.serviceResourceId = this.serviceResource.Id;
            let tempRegions =
                result.data.HOT_PreferredRegions__c != null ? result.data.HOT_PreferredRegions__c.split(';') : [];
            for (let tempRegion of tempRegions) {
                this.regions.push(tempRegion);
            }
        }
    }

    noServiceAppointments = true;
    @track allServiceAppointments;
    @track allServiceAppointmentsFiltered;
    wiredAllServiceAppointmentsResult;
    @wire(getOpenServiceAppointments)
    wiredAllServiceAppointments(result) {
        this.wiredAllServiceAppointmentsResult = result;
        if (result.data) {
            this.allServiceAppointments = result.data;
            this.noServiceAppointments = this.allServiceAppointments.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.allServiceAppointments = undefined;
        }
    }

    setDateFormats() {
        let tempServiceAppointments = [];
        for (let i = 0; i < this.allServiceAppointments.length; i++) {
            let tempRec = Object.assign({}, this.allServiceAppointments[i]);
            tempRec.DueDate = this.setDateFormat(this.allServiceAppointments[i].DueDate);
            tempRec.EarliestStartTime = this.setDateFormat(this.allServiceAppointments[i].EarliestStartTime);
            tempRec.HOT_DeadlineDate__c = this.allServiceAppointments[i].HOT_DeadlineDate__c.replaceAll('-', '.').split('.').reverse().join('.');
            tempRec.HOT_ReleaseDate__c = this.allServiceAppointments[i].HOT_ReleaseDate__c.replaceAll('-', '.').split('.').reverse().join('.');
            tempServiceAppointments[i] = tempRec;
        }
        this.allServiceAppointmentsFiltered = tempServiceAppointments;
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }

    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredAllServiceAppointmentsResult);
    }

   /* @track serviceAppointmentCommentDetails = [];
    abortSendingInterest() {
        this.template.querySelector('.commentPage').classList.add('hidden');
    }
    sendInterest() {
        if (this.selectedRows.length > 0) {
            this.serviceAppointmentCommentDetails = [];
            for (let row of this.selectedRows) {
                this.serviceAppointmentCommentDetails.push(
                    formatRecord(row, openServiceAppointmentFieldLabels.getSubFields('comment'))
                );
            }
            let commentPage = this.template.querySelector('.commentPage');
            commentPage.classList.remove('hidden');
            commentPage.focus();
        } else {
            alert('Velg oppdrag du ønsker å melde interesse om, så trykk på knappen.');
        }
    }
    confirmSendingInterest() {
        let serviceAppointmentIds = [];
        let comments = [];
        for (let i = 0; i < this.selectedRows.length; i++) {
            serviceAppointmentIds.push(this.selectedRows[i].Id);
        }
        this.template.querySelectorAll('.comment-field').forEach((element) => {
            comments.push(element.value);
        });
        createInterestedResources({ serviceAppointmentIds, comments }).then(() => {
            refreshApex(this.wiredAllServiceAppointmentsResult);
        });
        this.template.querySelector('.commentPage').classList.add('hidden');
    }*/
    @track regions = [];
    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.regions = fields.HOT_PreferredRegions__c;
        this.setDateFormats();
        this.template.querySelector('lightning-record-edit-form').submit(this.fieldValues);
        this.handleHideRegionFilter();
    }
    handleShowRegionFilter() {
        let regionPage = this.template.querySelector('.regionPage');
        regionPage.classList.remove('hidden');
        regionPage.focus();
    }
    handleHideRegionFilter() {
        this.template.querySelector('.regionPage').classList.add('hidden');
    }
}
