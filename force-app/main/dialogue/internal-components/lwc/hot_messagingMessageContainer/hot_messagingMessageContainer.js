import { LightningElement, api } from 'lwc';
import Id from '@salesforce/user/Id';

export default class messagingMessageContainer extends LightningElement {
    showpopover = false;
    isreply = false;
    isevent = false;
    showReplybutton;
    @api message;
    isoutbound;
    userid;

    connectedCallback() {
        this.userid = Id;
        //Indicate if the message is inbound or outbound, i.e left or right hand of the screen. tea

        this.isoutbound = !this.message.CRM_External_Message__c;

        if (this.message.CRM_Type__c == 'Event') {
            this.isevent = true;
        }
        if (typeof this.message.Previous_Message__c != 'undefined') {
            this.showReplybutton = false;
        }
        //if there is a reply, hide it
    }
    showdata() {
        this.showpopover = true;
    }
    hidedata() {
        this.showpopover = false;
    }
    replythreadPressed() {
        const selectedEvent = new CustomEvent('answerpressed', { detail: this.message.Id });
        this.dispatchEvent(selectedEvent);
    }
}
