import { LightningElement, api, wire, track } from 'lwc';
import getThreads from '@salesforce/apex/HOT_MessageHelper.getThreadsCollection';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThreadDispatcher';
import markAsReadByNav from '@salesforce/apex/HOT_MessageHelper.markAsReadByNav';
import getAccountOnRequest from '@salesforce/apex/HOT_MessageHelper.getAccountOnRequest';
import getRequestInformation from '@salesforce/apex/HOT_MessageHelper.getRequestInformation';
import getAccountOnWorkOrder from '@salesforce/apex/HOT_MessageHelper.getAccountOnWorkOrder';
import { refreshApex } from '@salesforce/apex';

export default class CrmMessagingMessageComponent extends LightningElement {
    showmodal = false;
    messageType = '';
    singlethread = false;
    _threadsforRefresh;
    showtaskmodal = false;
    showUserThreadbutton = false;
    showOrderThreadbutton = false;
    activeSectionMessage = '';
    threads;
    setCardTitle;
    hasError = false;

    @track isRequestMessages = false;
    @track showThreads = false;
    @track showButtonDiv;
    @track shownewbutton;
    @track buttonMessage;
    @track errorMessage;
    @track ThreadInfo;
    @track noAssignedResource = false;
    @track interestedResourceIsAssigned = false;

    @api recordId;
    @api singleThread;
    @api showClose;
    @api englishTextTemplate;
    @api textTemplate;
    @api objectApiName;

    @wire(getThreads, { recordId: '$recordId', singleThread: '$singleThread', type: '$messageType' }) //Calls apex and extracts messages related to this record
    wiredThreads(result) {
        this._threadsforRefresh = result;
        if (result.error) {
            this.error = result.error;
            this.errorMessage = this.error.body.message;
            this.hasError = true;
        } else if (result.data) {
            this.threads = result.data;
            if (this.threads.length > 0) {
                this.showButtonDiv = false;
            } else {
                this.showButtonDiv = true;
            }
        }
    }

    accountId;
    accountResult;
    @wire(getAccountOnRequest, { recordId: '$recordId' })
    wiredAccount(result) {
        this.accountResult = result;
        if (result.data) {
            this.accountId = result.data;
        }
    }

    handlenewpressed() {
        if (this.accountId == undefined) {
            getAccountOnWorkOrder({ recordId: this.recordId })
                .then((result) => {
                    this.accountId = result;
                    createThread({ recordId: this.recordId, accountId: this.accountId, type: this.messageType })
                        .then(() => {
                            this.showButtonDiv = false;
                            this.showThreads = true;
                            this.noAssignedResource = false;
                            this.interestedResourceIsAssigned = false;
                            return refreshApex(this._threadsforRefresh);
                        })
                        .catch((error) => {
                            if (this.objectApiName == 'HOT_InterestedResource__c') {
                                this.interestedResourceIsAssigned = true;
                            } else {
                                this.noAssignedResource = true;
                            }
                        });
                })
                .catch((error) => {});
        } else {
            createThread({ recordId: this.recordId, accountId: this.accountId, type: this.messageType })
                .then(() => {
                    this.showButtonDiv = false;
                    this.showThreads = true;
                    this.noAssignedResource = false;
                    this.interestedResourceIsAssigned = false;
                    return refreshApex(this._threadsforRefresh);
                })
                .catch((error) => {});
        }
    }

    get shownewbutton() {
        return this.threads.length == 0;
    }
    goToThreadTypeOrderer() {
        this.ThreadInfo = 'Du er i samtale med bestiller';
        refreshApex(this._threadsforRefresh);
        for (let thread in this.threads) {
            if (this.threads[thread].CRM_Type__c == 'HOT_BESTILLER-FORMIDLER') {
                this.messageType = 'HOT_BESTILLER-FORMIDLER';
                this.singleThread = true;
                refreshApex(this._threadsforRefresh);
                this.showThreads = true;
                event.preventDefault(); // prevent the default scroll behavior
                event.stopPropagation();
                break;
            } else {
                this.messageType = 'HOT_BESTILLER-FORMIDLER';
                this.buttonMessage = 'Klikk for å starte samtale med bestiller';
            }
        }
        if (this.threads.length == 0) {
            this.shownewbutton = true;
            this.messageType = 'HOT_BESTILLER-FORMIDLER';
            this.buttonMessage = 'Klikk for å starte samtale med bestiller';
        }
    }
    goToThreadTypeUser() {
        refreshApex(this._threadsforRefresh);
        this.ThreadInfo = 'Du er i samtale med bruker';
        for (let thread in this.threads) {
            if (this.threads[thread].CRM_Type__c == 'HOT_BRUKER-FORMIDLER') {
                this.messageType = 'HOT_BRUKER-FORMIDLER';
                this.singleThread = true;
                refreshApex(this._threadsforRefresh);
                this.showThreads = true;
                event.preventDefault(); // prevent the default scroll behavior
                event.stopPropagation();
                break;
            } else {
                this.messageType = 'HOT_BRUKER-FORMIDLER';
                this.buttonMessage = 'Klikk for å starte samtale med bruker';
            }
        }
        if (this.threads.length == 0) {
            this.shownewbutton = true;
            this.messageType = 'HOT_BRUKER-FORMIDLER';
            this.buttonMessage = 'Klikk for å starte samtale med bruker';
        }
    }

    get showSpinner() {
        return !this.threads && !this.hasError;
    }

    get cardTitle() {
        return this.setCardTitle ?? (this.singleThread === true ? 'Samtale' : 'Samtaler');
    }

    @api
    set cardTitle(cardTitle) {
        this.setCardTitle = cardTitle;
    }

    handleEnglishEvent(event) {
        const englishEvent = new CustomEvent('englisheventtwo', {
            detail: event.detail
        });
        this.dispatchEvent(englishEvent);
    }
    connectedCallback() {
        if (this.threads?.length > 0) {
            markAsReadByNav({ threadId: this.threads[0]?.Id });
        }
        getRequestInformation({ recordId: this.recordId })
            .then((result) => {
                this.isRequestMessages = true;
                if (result[0].IsAccountEqualOrderer__c == true) {
                    this.showUserThreadbutton = true;
                    this.showOrderThreadbutton = false;
                } else {
                    this.showUserThreadbutton = true;
                    this.showOrderThreadbutton = true;
                }
            })
            .catch((error) => {
                this.isRequestMessages = false;
                this.shownewbutton = true;
                this.showThreads = true;
                this.buttonMessage = 'Klikk for å starte samtale';
            });
    }
}
