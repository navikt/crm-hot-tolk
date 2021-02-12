import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import securityMeasures from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.INT_SecurityMeasures__c';
import reservations from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.HOT_Reservations__c';
import START_TIME from '@salesforce/schema/HOT_Request__c.StartTime__c';
import END_TIME from '@salesforce/schema/HOT_Request__c.EndTime__c';
import ACCOUNT from '@salesforce/schema/HOT_Request__c.Account__c';
import getRequestListFromAccountFromRequestId from '@salesforce/apex/HOT_RequestListContoller.getRequestListFromAccountFromRequestId';

export default class Hot_warningBannerRequest extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [securityMeasures, reservations, START_TIME, END_TIME, ACCOUNT]
    })
    record;

    get securityMeasures() {
        return getFieldValue(this.record.data, securityMeasures).replace(
            /;/g,
            ', '
        );
    }

    get hasSecurityMeasures() {
        return (
            getFieldValue(this.record.data, securityMeasures) != null &&
            getFieldValue(this.record.data, securityMeasures) != '[]'
        );
    }

    get reservations() {
        return getFieldValue(this.record.data, reservations);
    }

    get hasReservations() {
        return getFieldValue(this.record.data, reservations) != null;
    }

    @track allRequests;
    @track requests;
    @track error;
    wiredRequestsResult;
    @api accountId;

    @wire(getRequestListFromAccountFromRequestId, { accountId: '$recordId' })
    wiredRequest(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.allRequests = result.data;
            this.filterRequests();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.allRequests = undefined;
        }
    }
    isActive = false;
    filterRequests() {
        var tempRequests = [];
        for (var i = 0; i < this.allRequests.length; i++) {
            if (
                this.allRequests[i].ExternalRequestStatus__c != 'Avlyst' &&
                this.allRequests[i].ExternalRequestStatus__c != 'Dekket' &&
                this.allRequests[i].ExternalRequestStatus__c != 'Udekket'
            ) {
                tempRequests.push(this.allRequests[i]);
                if (this.allRequests[i].Id == this.recordId) {
                    this.isActive = true;
                }
            }
        }
        this.requests = tempRequests;
    }

    @track duplicateRequests = [];
    isDuplicate() {
        if (this.requests && this.isActive) {
            for (var i = 0; i < this.requests.length; i++) {
                if (
                    ((this.requests[i].StartTime__c <
                        getFieldValue(this.record.data, START_TIME) &&
                        getFieldValue(this.record.data, START_TIME) <
                            this.requests[i].EndTime__c) ||
                        (getFieldValue(this.record.data, START_TIME) <
                            this.requests[i].StartTime__c &&
                            this.requests[i].StartTime__c <
                                getFieldValue(this.record.data, END_TIME)) ||
                        (getFieldValue(this.record.data, START_TIME) ==
                            this.requests[i].StartTime__c &&
                            this.requests[i].EndTime__c ==
                                getFieldValue(this.record.data, END_TIME))) &&
                    this.requests[i].Id != this.recordId
                ) {
                    var arr = {
                        Id: '/' + this.requests[i].Id,
                        Name: this.requests[i].Name
                    };
                    this.duplicateRequests.push(arr);
                }
            }
        }
    }
    get getHasDuplicates() {
        this.isDuplicate();
        return this.duplicateRequests.length > 0 && this.isActive;
    }
}
