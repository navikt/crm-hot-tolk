import { LightningElement, api } from 'lwc';
import checkAccess from '@salesforce/apex/HOT_AccessErrorController.checkAccess';

export default class HotAccessErrorMessage extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api personRelationField;

    @api text;

    connectedCallback() {
        this.checkAccess();
    }

    checkAccess() {
        checkAccess({
            parentRecordId: this.recordId,
            parentObject: this.objectApiName,
            field: this.personRelationField
        })
            .then((data) => {
                this.text = data && data.length > 0 ? data : null;
            })
            .catch((error) => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }
}
