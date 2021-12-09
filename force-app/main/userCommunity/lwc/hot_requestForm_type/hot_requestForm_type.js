import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_requestForm_type extends NavigationMixin(LightningElement) {
    @api previousPage = 'Home';
    @track currentRequestType = 'Me';
    @track radiobuttons = [
        { label: 'For meg selv', value: 'Me', checked: true },
        { label: 'For en bruker', value: 'User' },
        { label: 'Til en virksomhet/arrangement/annet', value: 'Company' }
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

    goToPreviousPage() {
        window.scrollTo(0, 0);
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: this.previousPage
            }
        });
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
