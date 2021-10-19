import { LightningElement, track, api } from 'lwc';

export default class Hot_requestForm_request extends LightningElement {
    //TODO
    //api fieldValues
    // api validation
    // set field Values (api)
    // upload files

    @api fieldValues = {
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
    @api
    setFieldValues() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            this.fieldValues[element.name] = element.value;
        });
    }

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

    checkboxValue = false;
    getCheckboxValue(event) {
        this.checkboxValue = event.detail;
    }

    validateCheckbox() {
        this.template.querySelector('c-upload-files').validateCheckbox();
    }

    setFieldValuesOLD() {
        this.fieldValues.IsFileConsent__c = this.checkboxValue;
        if (this.sameLocation) {
            this.fieldValues.InterpretationStreet__c = this.fieldValues.MeetingStreet__c;
            this.fieldValues.InterpretationPostalCode__c = this.fieldValues.MeetingPostalCode__c;
            this.fieldValues.InterpretationPostalCity__c = this.fieldValues.MeetingPostalCity__c;
        }
    }
}
