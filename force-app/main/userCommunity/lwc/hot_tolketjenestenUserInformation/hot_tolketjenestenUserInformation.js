import { LightningElement, wire, track } from 'lwc';
import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';
import getNotificationPickListValues from '@salesforce/apex/HOT_UserInformationController.getNotificationPickListValues';
import changeUserNotificationSetting from '@salesforce/apex/HOT_UserInformationController.changeUserNotificationSetting';
import { formatDate } from 'c/datetimeFormatter';

export default class hot_tolketjenestenUserInformation extends LightningElement {
    @track person;
    @track recordId;
    @track options;
    @track selectedOption;
    @track securityMeassures;
    @track hasSecurityMeassures = false;
    @wire(getPerson)
    wiredGetPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
            getNotificationPickListValues({
                chosen: this.selectedOption
            }).then((data) => {
                this.options = data;
            });
            if (this.person.INT_SecurityMeasures__c != null || this.person.INT_SecurityMeasures__c != '') {
                this.hasSecurityMeassures = true;
                let secMeasures = JSON.parse(this.person.INT_SecurityMeasures__c);
                let securityMeasuresFormatted = [];
                secMeasures.forEach((sm) => {
                    console.log(sm.tiltaksType);
                    securityMeasuresFormatted.push(
                        sm.beskrivelse +
                            ' (' +
                            sm.tiltaksType +
                            '), gyldig: ' +
                            formatDate(sm.gyldigFraOgMed) +
                            ' - ' +
                            formatDate(sm.gyldigTilOgMed)
                    );
                });
                this.securityMeassures = securityMeasuresFormatted;
            }
        }
    }
    selectionChangeHandler(event) {
        changeUserNotificationSetting({ personId: this.recordId, newNotificationValue: event.target.value });
    }
}
