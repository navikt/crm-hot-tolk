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
    @track newSelectedOption;
    @track isReservedAgainstNotifications;
    @track newIsReservedAgainstNotifications;

    viewUserNotificationSettings = true;
    editUserNotification = false;

    picklistOptions = [
        { name: 'SMS', label: 'SMS', selected: false },
        { name: 'Push-varsel i appen', label: 'Push-varsel i appen', selected: false }
    ];

    @track securityMeassures;
    @track hasSecurityMeassures = false;

    @wire(getPerson)
    wiredGetPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
            this.selectedOption = this.person.HOT_NotificationChannel__c;
            this.isReservedAgainstNotifications = this.person.HOT_IsReservationAgainstNotifications__c;
            this.newSelectedOption = this.selectedOption;
            getNotificationPickListValues({
                chosen: this.selectedOption
            }).then((data) => {
                this.options = data;
                this.picklistOptions.forEach((element) => {
                    if (element.name === this.selectedOption) {
                        element.selected = true;
                    } else {
                        element.selected = false;
                    }
                });
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
        this.newSelectedOption = event.detail.name;
        this.picklistOptions.forEach((element) => {
            if (element.name === event.detail.name) {
                element.selected = true;
            } else {
                element.selected = false;
            }
        });
    }
    editUserNotificationBtn() {
        this.viewUserNotificationSettings = false;
        this.editUserNotification = true;
    }
    handleAbort() {
        this.viewUserNotificationSettings = true;
        this.editUserNotification = false;
        this.picklistOptions.forEach((element) => {
            if (element.name === this.selectedOption) {
                element.selected = true;
            } else {
                element.selected = false;
            }
        });
    }
    handleOptionalCheckbox(event) {
        this.newIsReservedAgainstNotifications = event.detail;
    }
    handleSubmit() {
        this.viewUserNotificationSettings = true;
        this.editUserNotification = false;
        changeUserNotificationSetting({
            personId: this.recordId,
            newNotificationValue: this.newSelectedOption,
            isReservedAgainstNotifications: this.newIsReservedAgainstNotifications
        }).then(() => {
            this.selectedOption = this.newSelectedOption;
            if (typeof this.newIsReservedAgainstNotifications == 'boolean') {
                this.isReservedAgainstNotifications = this.newIsReservedAgainstNotifications;
            }
        });
    }
}
