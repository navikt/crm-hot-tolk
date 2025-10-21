import { LightningElement, api } from 'lwc';

export default class Hot_messagingCommunityMessageOutbound_v2 extends LightningElement {
    @api message;

    // Uppercase on the first letter of each word
    get formattedFirstName() {
        if (!this.message?.CRM_From_First_Name__c) {
            return '';
        }

        return this.message.CRM_From_First_Name__c.trim()
            .split(' ')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join(' ');
    }
    get date() {
        if (!this.message.CRM_Sent_date__c) return '';
        let rawDate = new Date(this.message.CRM_Sent_date__c);
        if (rawDate == 'Invalid Date' || isNaN(rawDate)) {
            console.log('navFormattedDate: Bad date format.');
            return '';
        }
        // Dato
        let formatter = new Intl.DateTimeFormat('no', { day: 'numeric', month: 'long', year: 'numeric' });
        let date = formatter.format(rawDate);
        // Tid
        formatter = new Intl.DateTimeFormat('no', { hour: 'numeric', minute: 'numeric' });
        let timeParts = formatter.formatToParts(rawDate);
        let hour = timeParts.find((e) => e.type === 'hour').value;
        let minute = timeParts.find((e) => e.type === 'minute').value;
        return date + ', kl. ' + hour + '.' + minute;
    }

    get ariaLabelText() {
        return 'Melding fra deg, sendt ' + this.date;
    }
}
