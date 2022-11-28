import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';

export default class Hot_welcomeMessage extends LightningElement {
    @track name;
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD]
    })
    wireuser({ data }) {
        if (data) {
            this.name = data.fields.FirstName.value;
        }
    }
}
