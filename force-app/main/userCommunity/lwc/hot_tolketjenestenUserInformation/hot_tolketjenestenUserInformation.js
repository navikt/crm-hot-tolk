import { LightningElement, wire, track } from 'lwc';
import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';
import getNotificationPickListValues from '@salesforce/apex/HOT_UserInformationController.getNotificationPickListValues';
import changeUserNotificationsetting from '@salesforce/apex/HOT_UserInformationController.changeUserNotificationsetting';

export default class hot_tolketjenestenUserInformation extends LightningElement {
    @track person;
    @track recordId;
    @track options;
    @track selectedOption;
    @track testtest;
    @wire(getPerson)
    wiredGetPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
            this.selectedOption = this.person.HOT_NotificationChannel__c;
            getNotificationPickListValues({
                chosen: this.selectedOption
            }).then((data) => {
                this.options = data;
            });
        }
    }
    selectionChangeHandler(event) {
        alert('Du endret til: ' + event.target.value + ' Personid: ' + this.recordId);
        const data = '';
        data = changeUserNotificationsetting({ personId: this.recordId, newNotificationValue: event.target.value });
        alert(data);
    }
}
