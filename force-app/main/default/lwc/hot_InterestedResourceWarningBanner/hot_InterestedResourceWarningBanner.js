import { LightningElement, api, wire, track } from 'lwc';
import checkForOverlap from '@salesforce/apex/HOT_InterestedResourceBannerController.checkForOverlap';
import { formatDate } from 'c/datetimeFormatter';

export default class Hot_InterestedResourceWarningBanner extends LightningElement {
    @api recordId;
    @track serviceAppointments = [];
    @track serviceAppointments2 = [];
    @track hasOverlap = false;
    oppdragsInfo = '';

    connectedCallback() {
        let recordId = this.recordId;

        checkForOverlap({ recordId: recordId }).then((data) => {
            this.serviceAppointments = data;
            if (this.serviceAppointments.length != 0) {
                this.hasOverlap = true;
                // this.serviceAppointments.forEach((element) => {
                //     let startTimeFormatted = new Date(element.SchedStartTime);
                //     let endTimeFormatted = new Date(element.SchedEndTime);

                //     this.oppdragsInfo +=
                //         element.AppointmentNumber +
                //         ' \n ' +
                //         startTimeFormatted.getDate() +
                //         '.' +
                //         startTimeFormatted.getMonth() +
                //         '.' +
                //         startTimeFormatted.getFullYear() +
                //         ' ' +
                //         startTimeFormatted.getHours() +
                //         ':' +
                //         endTimeFormatted.getMinutes() +
                //         ' - ' +
                //         endTimeFormatted.getDate() +
                //         '.' +
                //         endTimeFormatted.getMonth() +
                //         '.' +
                //         endTimeFormatted.getFullYear() +
                //         ' ' +
                //         endTimeFormatted.getHours() +
                //         ':' +
                //         endTimeFormatted.getMinutes();
                // });
                for (let record of data) {
                    let startTimeFormatted = new Date(record.SchedStartTime);
                    let endTimeFormatted = new Date(record.SchedEndTime);
                    record.Link = '/lightning/r/' + record.Id + '/view';
                    record.oppdragsInfo =
                        startTimeFormatted.getDate() +
                        '.' +
                        startTimeFormatted.getMonth() +
                        '.' +
                        startTimeFormatted.getFullYear() +
                        ' ' +
                        startTimeFormatted.getHours() +
                        ':' +
                        endTimeFormatted.getMinutes() +
                        ' - ' +
                        endTimeFormatted.getDate() +
                        '.' +
                        endTimeFormatted.getMonth() +
                        '.' +
                        endTimeFormatted.getFullYear() +
                        ' ' +
                        endTimeFormatted.getHours() +
                        ':' +
                        endTimeFormatted.getMinutes();
                    this.serviceAppointments2.push(record);
                }
            }
        });
    }
}
