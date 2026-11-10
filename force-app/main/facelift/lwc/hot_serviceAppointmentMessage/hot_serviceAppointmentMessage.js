import { LightningElement, api, wire } from 'lwc';
import getMessages from '@salesforce/apex/HOT_ServiceAppointmentMessageController.getMessages';
import { refreshApex } from '@salesforce/apex';

export default class Hot_serviceAppointmentMessage extends LightningElement {
    @api header = 'Beskjed fra formidler';

    _recordId;
    hasRefreshedMessages = false;
    messages = [];
    errorMessage;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value === this._recordId) {
            return;
        }
        this._recordId = value || undefined;
        this.hasRefreshedMessages = false;
        this.messages = [];
        this.errorMessage = undefined;
    }

    @wire(getMessages, { recordId: '$recordId' })
    wiredMessages(result) {
        const { data, error } = result;
        if (!this.recordId) {
            return;
        }
        if (!this.hasRefreshedMessages && (data || error)) {
            this.hasRefreshedMessages = true;
            refreshApex(result).catch(() => {});
        }
        if (error) {
            console.error('Kunne ikke hente beskjeder til oppdraget', error);
            this.errorMessage = 'Kunne ikke hente beskjeder til oppdraget. Prøv igjen senere.';
            this.messages = [];
        } else if (data) {
            this.messages = data.map((message, index) => ({
                id: message.Id,
                message: message.Message__c,
                createdDate: message.CreatedDate,
                created: this.formatDateTime(message.CreatedDate),
                isNewest: index === 0 && data.length > 1
            }));
            this.errorMessage = undefined;
        }
    }

    get hasMessages() {
        return this.messages.length > 0;
    }

    formatDateTime(value) {
        const date = new Date(value);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${day}.${month}.${date.getFullYear()}, Kl ${hours}:${minutes}`;
    }
}
