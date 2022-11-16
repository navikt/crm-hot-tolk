import { LightningElement, wire, track } from 'lwc';
import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';
import getNotificationPickListValues from '@salesforce/apex/HOT_UserInformationController.getNotificationPickListValues';
import changeUserNotificationSetting from '@salesforce/apex/HOT_UserInformationController.changeUserNotificationSetting';

export default class hot_tolketjenestenUserInformation extends LightningElement {
    @track person;
    @track recordId;
    @track options;
    @track selectedOption;
    @track newSelectedOption;
    @track isReservedAgainsAppNotifications;
    @track newIsReservedAgainsAppNotifications;

    viewUserNotificationSettings = true;
    editUserNotification = false;

    picklistOptions = [
        { name: 'SMS', label: 'SMS', selected: false },
        { name: 'Push-varsel i appen', label: 'Push-varsel i appen', selected: false }
    ];
    @wire(getPerson)
    wiredGetPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
            this.selectedOption = this.person.HOT_NotificationChannel__c;
            this.isReservedAgainsAppNotifications = this.person.HOT_ReservationAgainstAppNotifications__c;
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
        this.newIsReservedAgainsAppNotifications = event.detail;
    }
    handleSubmit() {
        this.viewUserNotificationSettings = true;
        this.editUserNotification = false;

        changeUserNotificationSetting({
            personId: this.recordId,
            newNotificationValue: this.newSelectedOption,
            isReservedAgainstAppNotifications: this.newIsReservedAgainsAppNotifications
        }).then(() => {
            this.selectedOption = this.newSelectedOption;
            this.isReservedAgainsAppNotifications = this.newIsReservedAgainsAppNotifications;
        });
    }
}
