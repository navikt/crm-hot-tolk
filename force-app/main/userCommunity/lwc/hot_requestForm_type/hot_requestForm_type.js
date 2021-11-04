import { LightningElement, track } from 'lwc';

export default class Hot_requestForm_type extends LightningElement {
    @track currentRequestType;
    @track radiobuttons = [
        { label: 'For meg selv', value: 'Me', checked: true },
        { label: 'For en bruker', value: 'User' },
        { label: 'Til et arrangement/virksomhet/annet', value: 'Company' }
    ];

    handleRequestTypeChange(event) {
        let radiobuttonValues = event.detail;
        radiobuttonValues.forEach((element) => {
            if (element.checked) {
                this.currentRequestType = element.value;
            }
        });
        this.result.type = this.currentRequestType;
    }

    handleNextButtonClicked() {
        switch (this.currentRequestType) {
            case 'Me':
                this.result.requestForm = true;
                break;
            case 'User':
                this.result.userForm = true;
                this.result.ordererForm = true;
                this.result.requestForm = true;
                break;
            case 'Company':
                this.result.ordererForm = true;
                this.result.companyForm = true;
                this.result.requestForm = true;
                break;
            default:
        }
        if (this.currentRequestType !== undefined) {
            this.sendResult();
        }
    }

    @track result = {
        type: this.currentRequestType,
        ordererForm: false,
        userForm: false,
        companyForm: false,
        requestForm: false
    };
    sendResult() {
        const selectedEvent = new CustomEvent('requestformtyperesult', {
            detail: this.result
        });
        this.dispatchEvent(selectedEvent);
    }
}
