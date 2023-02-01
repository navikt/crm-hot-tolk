import { LightningElement, api, wire, track } from 'lwc';
import checkForOverlap from '@salesforce/apex/HOT_InterestedResourceBannerController.checkForOverlap';
import { formatDate } from 'c/datetimeFormatter';

export default class Hot_InterestedResourceWarningBanner extends LightningElement {
    @api recordId;
    @track serviceAppointments = [];
    @track hasOverlap = false;
    oppdragsInfo = '';

    connectedCallback() {
        let recordId = this.recordId;

        checkForOverlap({ recordId: recordId }).then((data) => {
            for (let record of data) {
                let startTimeFormatted = new Date(record.SchedStartTime);
                let endTimeFormatted = new Date(record.SchedEndTime);
                record.Link = '/lightning/r/' + record.Id + '/view';
                record.oppdragsInfo =
                    startTimeFormatted.getDate() +
                    '.' +
                    (startTimeFormatted.getMonth() + 1) +
                    '.' +
                    startTimeFormatted.getFullYear() +
                    ' ' +
                    ('0' + startTimeFormatted.getHours()).substr(-2) +
                    ':' +
                    ('0' + startTimeFormatted.getMinutes()).substr(-2) +
                    ' - ' +
                    endTimeFormatted.getDate() +
                    '.' +
                    (endTimeFormatted.getMonth() + 1) +
                    '.' +
                    endTimeFormatted.getFullYear() +
                    ' ' +
                    ('0' + endTimeFormatted.getHours()).substr(-2) +
                    ':' +
                    ('0' + endTimeFormatted.getMinutes()).substr(-2);
                this.serviceAppointments.push(record);
            }
            this.hasOverlap = this.serviceAppointments.length > 0;
        });
    }
}
