import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'HOT_Request__c.Name',
    'HOT_Request__c.Subject__c',
    'HOT_Request__c.Status__c',
    'HOT_Request__c.StartTime__c',
    'HOT_Request__c.IsSerieoppdrag__c',
    'HOT_Request__c.Account__r.Name',
    'HOT_Request__c.Account__r.INT_PersonIdent__c',
    'HOT_Request__c.InterpretationMethod__r.Name'
];

export default class hot_tindRequestHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;

    requestData;

    @track loadingStates = {
        getRequest: true
    };

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            const f = data.fields;
            this.requestData = {
                Name: f.Name?.value,
                Subject__c: f.Subject__c?.value,
                Status__c: f.Status__c?.value,
                StartTime__c: f.StartTime__c?.value,
                IsSerieoppdrag__c: f.IsSerieoppdrag__c?.value,
                Account__r: {
                    Name: f.Account__r?.value?.fields?.Name?.value,
                    INT_PersonIdent__c: f.Account__r?.value?.fields?.INT_PersonIdent__c?.value
                },
                InterpretationMethod__r: {
                    Name: f.InterpretationMethod__r?.value?.fields?.Name?.value
                }
            };
            this.loadingStates.getRequest = false;
        } else if (error) {
            this.loadingStates.getRequest = false;
            console.error('getRecord error:', error);
        }
    }

    get isLoading() {
        return Object.keys(this.loadingStates).some((key) => this.loadingStates[key]);
    }
}
