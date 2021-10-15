import { LightningElement, track, api } from 'lwc';

export default class Hot_requestForm_type extends LightningElement {
    @track currentRequestType = 'Me';
    @track publicEventForm = false;
    @track eventType = null;
    @track showInformationSharingText = true;

    get requestTypes() {
        return [
            { label: 'For meg selv', value: 'Me' },
            { label: 'For en bruker', value: 'User' },
            { label: 'For en bruker, virksomheten betaler', value: 'Company' },
            {
                label: 'Til et arrangement, virksomheten betaler',
                value: 'PublicEvent'
            }
        ];
    }

    handleRequestTypeChange(event) {
        this.currentRequestType = event.detail.value;
        if (this.currentRequestType === 'PublicEvent') {
            this.publicEventForm = true;
        } else {
            this.publicEventForm = false;
            this.eventType = null;
        }
    }

    get eventTypes() {
        return [
            { label: 'Idrettsarrangement', value: 'SportingEvent' },
            { label: 'Annet', value: 'OtherEvent' }
        ];
    }
    handleChoiceOfEvent(event) {
        this.eventType = event.detail.value;
    }

    onHandleNeste() {
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
                this.result.userForm = true;
                this.result.ordererForm = true;
                this.result.companyForm = true;
                this.result.requestForm = true;
                break;
            case 'Event':
                this.validateEventType();
                this.result.ordererForm = true;
                this.result.companyForm = true;
                this.result.requestForm = true;
                break;
            default:
        }
        if (this.isValid()) {
            this.sendResult();
        }
    }
    isValid() {
        return this.currentRequestType !== 'Event' || (this.currentRequestType === 'Event' && this.eventType !== null);
    }
    result = {
        type: this.currentRequestType,
        eventType: this.eventType,
        ordererForm: false,
        userForm: false,
        companyForm: false,
        requestForm: false
    };
    sendResult() {
        const selectedEvent = new CustomEvent('requestFormTypeResult', {
            detail: this.result
        });
        this.dispatchEvent(selectedEvent);
    }

    typeOfEventElement;
    renderedCallback() {
        this.typeOfEventElement = this.template.querySelector('.skjema').querySelector('.type-arrangement');
    }

    validateEventType() {
        if (this.eventType === null) {
            this.typeOfEventElement.setCustomValidity('Du må velge type arrangement.');
            this.typeOfEventElement.focus();
        } else {
            this.typeOfEventElement.setCustomValidity('');
        }
        this.typeOfEventElement.reportValidity();
    }
}
