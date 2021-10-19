import { LightningElement, track } from 'lwc';

export default class Hot_requestForm_request extends LightningElement {
    @track fieldValues = {
        Name: '',
        Subject__c: '',
        StartTime__c: '',
        EndTime__c: '',
        MeetingStreet__c: '',
        MeetingPostalCity__c: '',
        MeetingPostalCode__c: '',
        Description__C: '',
        IsFileConsent__c: false,
        IsOtherEconomicProvicer__c: false,
        IsOrdererWantStatusUpdateOnSMS__c: false,
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        AdditionalInvoiceText__c: '',
        UserName__c: '',
        UserPersonNumber__c: '',
        Orderer__c: '',
        OrdererEmail__c: '',
        OrdererPhone__c: '',
        Source__c: 'Community',
        Type__c: '',
        EventType__c: ''
    };

    checkPostalCode(event) {
        //check postal code ExpReg
    }

    @track sameLocation = true;
    value = 'yes';
    get options() {
        return [
            { label: 'Ja', value: 'yes' },
            { label: 'Nei', value: 'no' }
        ];
    }
    toggled() {
        this.sameLocation = !this.sameLocation;
    }
}
