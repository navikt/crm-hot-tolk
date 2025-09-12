import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_requestForm_type_v2 extends NavigationMixin(LightningElement) {
    @api previousPage = 'home';
    @track currentRequestType = 'Me';

    user =
        'Dette velger du dersom du som privatperson bestiller for en annen person. For eksempel kan du bestille for ditt barn, din partner eller en venn';
    company =
        'Dette velger du om du er ansatt i en virksomhet. Du kan underveis i bestillingen koble den til en bestemt bruker.  For eksempel om du er ansatt i en kommune/på et sykehus, og skal snakke med en bruker. Eller du ønsker å bestille tolk til et arrangement, for eksempel tolking av 17. mai arrangement, gudstjeneste i døvekirken og lignende, uten at det er knyttet til en bestemt bruker.';

    @track radiobuttons = [
        { label: 'For meg selv', value: 'Me', checked: true, helptext: null },
        { label: 'For en bruker', value: 'User', helptext: this.user },
        { label: 'På vegne av en virksomhet/arrangement/annet', value: 'Company', helptext: this.company }
    ];

    get radioWrappers() {
        return this.radiobuttons.map((rb) => ({
            singleRadioArray: [rb],
            helptext: rb.helptext,
            value: rb.value
        }));
    }

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
