import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import IS_RELEASED from '@salesforce/schema/ServiceAppointment.HOT_IsReleasedToFreelance__c';
import getAvailableResources from '@salesforce/apex/HOT_WageClaimListController.getAvailableResources';

export default class Hot_warningBannerServiceAppointment extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [IS_RELEASED] })
    record;

    get isReleased() {
        return getFieldValue(this.record.data, IS_RELEASED);
    }

    @track isAvailableInterpreters;
    @track wageClaims = [];
    wiredwageClaimsResult;
    @wire(getAvailableResources, { recordId: '$recordId' })
    wiredwageClaims(result) {
        console.log('derp');
        console.log(JSON.stringify(result));
        this.wiredwageClaimsResult = result;
        if (result.data) {
            this.error = undefined;
            for (let record of result.data) {
                let startTime = new Date(record.StartTime__c);
                let endTime = new Date(record.EndTime__c);
                let temp = new Object({
                    Id: record.Id,
                    ServiceResource__c: record.ServiceResource__c,
                    ServiceResourceName: record.ServiceResource__r.Name,
                    ServiceTerritory: record.ServiceResource__r.HOT_ServiceTerritory__r.Name,
                    StartTime: this.formatTime(startTime.getHours()) + ':' + this.formatTime(startTime.getMinutes()),
                    EndTime: this.formatTime(endTime.getHours()) + ':' + this.formatTime(endTime.getMinutes()),
                    Link: '/lightning/r/' + record.ServiceResource__c + '/view'
                });
                this.wageClaims.push(temp);
            }
            this.isAvailableInterpreters = this.wageClaims.length > 0;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @track isSeeMore = false;
    showAvailableInterpreters() {
        this.isSeeMore = true;
    }

    formatTime(number) {
        console.log(number);
        return number > 9 ? number.toString() : '0' + number.toString();
    }
}
