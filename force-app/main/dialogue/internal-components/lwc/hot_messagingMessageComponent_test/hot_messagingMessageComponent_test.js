import { LightningElement, api, wire, track } from 'lwc';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThreadDispatcher';
import getUserContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getThreadsAndParticipants from '@salesforce/apex/HOT_ThreadParticipants_dev.getParticipantsByRelatedObjectAndThreadTypes';
import getAccountOnRequest from '@salesforce/apex/HOT_MessageHelper.getAccountOnRequest';
import getRequestInformation from '@salesforce/apex/HOT_MessageHelper.getRequestInformation';
import getWorkOrderInformation from '@salesforce/apex/HOT_MessageHelper.getWorkOrderInformation';
import getAccountOnWorkOrder from '@salesforce/apex/HOT_MessageHelper.getAccountOnWorkOrder';

export default class CrmMessagingMessageComponent extends LightningElement {
    showUserThreadbutton = false;
    showOrderThreadbutton = false;
    showUserOrdererThreadbutton = false;
    showUserInterpreterThreadbutton = false;
    showInterpreterInterpreterThreadbutton = false;
    showInterpreterThreadbutton = false;
    showOfficeThreadbutton = false;
    //show flows
    userSetToRedactionFlow = false;
    ordererSetToRedactionFlow = false;
    userInterpreterSetToRedactionFlow = false;
    interpreterInterpreterSetToRedactionFlow = false;
    interpreterSetToRedactionFlow = false;
    officeSetToRedactionFlow = false;
    runningThreadCreate = false;
    //flow variables
    userRedactionFlowVariables = [];
    ordererRedactionFlowVariables = [];
    userInterpreterRedactionFlowVariables = [];
    interpreterInterpreterRedactionFlowVariables = [];
    interpreterRedactionFlowVariables = [];
    officeRedactionFlowVariables = [];

    openThreads = {
        'HOT_TOLK-TOLK': null,
        'HOT_BRUKER-TOLK': null,
        'HOT_BESTILLER-FORMIDLER': null,
        'HOT_BRUKER-FORMIDLER': null,
        'HOT_TOLK-RESSURSKONTOR': null,
        'HOT_TOLK-FORMIDLER': null
    };
    threadLabels = {
        'HOT_TOLK-TOLK': 'Samtale med medtolker',
        'HOT_BRUKER-TOLK': 'Samtale med bruker og tolk',
        'HOT_BESTILLER-FORMIDLER': 'Samtale med bestiller',
        'HOT_BRUKER-FORMIDLER': 'Samtale med bruker',
        'HOT_TOLK-RESSURSKONTOR': 'Samtale med tolk',
        'HOT_TOLK-FORMIDLER': 'Samtale med tolk'
    };
    threadCmpMap = {
        'HOT_TOLK-TOLK': '[data-int-int-thread]',
        'HOT_BRUKER-TOLK': '[data-user-int-thread]',
        'HOT_BESTILLER-FORMIDLER': '[data-orderer-thread]',
        'HOT_BRUKER-FORMIDLER': '[data-user-thread]',
        'HOT_TOLK-RESSURSKONTOR': '[data-office-thread]',
        'HOT_TOLK-FORMIDLER': '[data-int-thread]'
    };
    tabLabels = {
        'HOT_TOLK-TOLK': {
            open: 'Medtolker',
            new: 'Ny samtale med medtolker'
        },
        'HOT_BRUKER-TOLK': {
            open: 'Bruker og tolk',
            new: 'Ny samtale med bruker og tolk'
        },
        'HOT_BESTILLER-FORMIDLER': {
            open: 'Bestiller',
            new: 'Ny samtale med bestiller'
        },
        'HOT_BRUKER-FORMIDLER': {
            open: 'Bruker',
            new: 'Ny samtale med bruker'
        },
        'HOT_TOLK-RESSURSKONTOR': {
            open: 'Tolk',
            new: 'Ny samtale med tolk'
        },
        'HOT_TOLK-FORMIDLER': {
            open: 'Tolk',
            new: 'Ny samtale med tolk'
        }
    };
    threadTypesOfInterest = [];
    @track threadsAndParticipants;

    @track errorMessage;
    @track noAssignedResource = false;
    @track interestedResourceIsAssigned = false;
    threadParticipants;

    userContactId;

    @api recordId;
    @api singleThread;
    @api showClose;
    @api englishTextTemplate;
    @api textTemplate;
    @api objectApiName;

    @wire(getUserContactId)
    wiredUserContactId({ data }) {
        if (data) this.userContactId = data;
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

    handleEnglishEvent(event) {
        const englishEvent = new CustomEvent('englisheventtwo', {
            detail: event.detail
        });
        this.dispatchEvent(englishEvent);
    }
    renderedCallback() {}
    connectedCallback() {
        if (this.objectApiName == 'HOT_Request__c') {
            getRequestInformation({ recordId: this.recordId })
                .then((result) => {
                    if (result[0].IsAccountEqualOrderer__c == true) {
                        this.showUserThreadbutton = true;
                        this.showOrderThreadbutton = false;
                        this.showUserOrdererThreadbutton = false;
                        this.threadTypesOfInterest = ['HOT_BRUKER-FORMIDLER'];
                    } else if (result[0].Account__c == null && result[0].Orderer__c != null) {
                        this.showUserThreadbutton = false;
                        this.showOrderThreadbutton = true;
                        this.showUserOrdererThreadbutton = false;
                        this.threadTypesOfInterest = ['HOT_BESTILLER-FORMIDLER'];
                    } else if (result[0].Account__c != null && result[0].Orderer__c == null) {
                        this.showUserThreadbutton = true;
                        this.showOrderThreadbutton = false;
                        this.showUserOrdererThreadbutton = false;
                        this.threadTypesOfInterest = ['HOT_BRUKER-FORMIDLER'];
                    } else {
                        this.showUserThreadbutton = true;
                        this.showOrderThreadbutton = true;
                        this.showUserOrdererThreadbutton = true;
                        this.threadTypesOfInterest = ['HOT_BRUKER-FORMIDLER', 'HOT_BESTILLER-FORMIDLER'];
                    }
                    this.getThreadAndParticipants();
                })
                .catch((error) => {
                    console.log(error);
                });
        } else if (this.objectApiName == 'HOT_WorkOrder__c') {
            getWorkOrderInformation({ recordId: this.recordId })
                .then((result) => {
                    if (result[0].HOT_TotalNumberOfInterpreters__c > 1) {
                        this.showInterpreterInterpreterThreadbutton = true;
                        this.showUserInterpreterThreadbutton = true;
                        this.threadTypesOfInterest = ['HOT_TOLK-TOLK', 'HOT_BRUKER-TOLK'];
                    } else {
                        this.showInterpreterInterpreterThreadbutton = false;
                        this.showUserInterpreterThreadbutton = true;
                        this.threadTypesOfInterest = ['HOT_BRUKER-TOLK'];
                    }
                    this.getThreadAndParticipants();
                })
                .catch((error) => {
                    console.log(error);
                });
        } else if (this.objectApiName == 'HOT_WageClaim__c') {
            this.showOfficeThreadbutton = true;
            this.threadTypesOfInterest = ['HOT_TOLK-RESSURSKONTOR'];
            this.getThreadAndParticipants();
        } else if (this.objectApiName == 'ServiceAppointment' || this.objectApiName == 'HOT_InterestedResource__c') {
            console.log('ServiceAppointment object for messaging component');
            this.showInterpreterThreadbutton = true;
            this.threadTypesOfInterest = ['HOT_TOLK-FORMIDLER'];
            this.getThreadAndParticipants();
        } else {
            console.log('Not supportet object for messaging component');
        }
    }

    getThreadAndParticipants() {
        getThreadsAndParticipants({
            relatedObjectId: this.recordId,
            threadTypesOfInterest: this.threadTypesOfInterest
        })
            .then((result) => {
                console.log('threads and participants result: ' + JSON.stringify(result));
                this.threadsAndParticipants = result;
            })
            .catch((error) => {
                console.log('Error getting threads and participants: ');
                console.log(error);
            });
    }
    setToRedaction(event, name) {
        event.stopPropagation();
        const toolbaractionEvent = new CustomEvent('toolbaraction', {
            bubbles: true,
            composed: true,
            detail: {
                name: name
            }
        });
        event.target.dispatchEvent(toolbaractionEvent);
    }
    userRedaction(event) {
        this.setToRedaction(event, 'userredactionclicked');
    }
    ordererRedaction(event) {
        this.setToRedaction(event, 'ordererredactionclicked');
    }
    userInterpreterRedaction(event) {
        this.setToRedaction(event, 'userinterpreterredactionclicked');
    }
    interpreterInterpreterRedaction(event) {
        this.setToRedaction(event, 'interpreterinterpreterredactionclicked');
    }
    interpreterRedaction(event) {
        this.setToRedaction(event, 'interpreterredactionclicked');
    }
    officeRedaction(event) {
        this.setToRedaction(event, 'officeredactionclicked');
    }
    userToolbarAction(event) {
        if (event.detail.name === 'userredactionclicked' && event.detail.threadId) {
            this.userRedactionFlowVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: event.detail.threadId
                }
            ];
            this.userSetToRedactionFlow = true;
        }
    }
    ordererToolbarAction(event) {
        if (event.detail.name === 'ordererredactionclicked' && event.detail.threadId) {
            this.ordererRedactionFlowVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: event.detail.threadId
                }
            ];
            this.ordererSetToRedactionFlow = true;
        }
    }
    userInterpreterToolbarAction(event) {
        if (event.detail.name === 'userinterpreterredactionclicked' && event.detail.threadId) {
            this.userInterpreterRedactionFlowVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: event.detail.threadId
                }
            ];
            this.userInterpreterSetToRedactionFlow = true;
        }
    }
    interpreterInterpreterToolbarAction(event) {
        if (event.detail.name === 'interpreterinterpreterredactionclicked' && event.detail.threadId) {
            this.interpreterInterpreterRedactionFlowVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: event.detail.threadId
                }
            ];
            this.interpreterInterpreterSetToRedactionFlow = true;
        }
    }
    interpreterToolbarAction(event) {
        if (event.detail.name === 'interpreterredactionclicked' && event.detail.threadId) {
            this.interpreterRedactionFlowVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: event.detail.threadId
                }
            ];
            this.interpreterSetToRedactionFlow = true;
        }
    }
    officeToolbarAction(event) {
        if (event.detail.name === 'officeredactionclicked' && event.detail.threadId) {
            this.officeRedactionFlowVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: event.detail.threadId
                }
            ];
            this.officeSetToRedactionFlow = true;
        }
    }
    handleUserRedactionFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.userRedactionFlowVariables = [];
            this.userSetToRedactionFlow = false;
        }
    }
    handleOrdererRedactionFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.ordererRedactionFlowVariables = [];
            this.ordererSetToRedactionFlow = false;
        }
    }
    handleUserInterpreterRedactionFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.userInterpreterRedactionFlowVariables = [];
            this.userInterpreterSetToRedactionFlow = false;
        }
    }
    handleInterpreterInterpreterRedactionFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.interpreterInterpreterRedactionFlowVariables = [];
            this.interpreterInterpreterSetToRedactionFlow = false;
        }
    }
    handleInterpreterRedactionFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.interpreterRedactionFlowVariables = [];
            this.interpreterSetToRedactionFlow = false;
        }
    }
    handleOfficeRedactionFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.officeRedactionFlowVariables = [];
            this.officeSetToRedactionFlow = false;
        }
    }
    get participants() {
        if (this.threadParticipants) {
            return this.threadParticipants.map((participant) => {
                return {
                    label: participant.name + (participant.role ? ' (' + participant.role + ')' : ''),
                    iconName: 'standard:account',
                    key: Math.floor(Math.random() * 1000000),
                    theme: 'slds-theme_info'
                };
            });
        }
        return null;
    }
    get participantsReadBy() {
        if (this.threadParticipants) {
            return this.threadParticipants
                .filter((participant) => {
                    console.log(participant);
                    return participant.hasRead;
                })
                .map((participant) => {
                    console.log(participant);
                    return {
                        label: participant.name + (participant.role ? ' (' + participant.role + ')' : ''),
                        iconName: 'standard:account',
                        key: Math.floor(Math.random() * 1000000),
                        theme: 'slds-theme_success'
                    };
                });
        }
        return null;
    }
    get threadsAndParticipantsByType() {
        if (!this.threadsAndParticipants) {
            return [];
        }
        return this.threadTypesOfInterest.map((type) => {
            const hasThreads =
                this.threadsAndParticipants[type] && Object.keys(this.threadsAndParticipants[type]).length > 0;
            let result = {
                label: this.threadLabels[type],
                key: type,
                hasThreads: hasThreads,
                threads: !hasThreads
                    ? null
                    : Object.keys(this.threadsAndParticipants[type]).map((threadId) => {
                          return {
                              threadId: threadId,
                              participants: this.threadsAndParticipants[type][threadId].map((participant) => {
                                  return {
                                      label: participant.name + (participant.role ? ' (' + participant.role + ')' : ''),
                                      iconName: 'standard:account',
                                      key: Math.floor(Math.random() * 1000000),
                                      theme: 'slds-theme_info'
                                  };
                              }),
                              participantsReadBy: this.threadsAndParticipants[type][threadId]
                                  .filter((participant) => participant.hasRead)
                                  .map((participant) => {
                                      return {
                                          label:
                                              participant.name +
                                              (participant.role ? ' (' + participant.role + ')' : ''),
                                          iconName: 'standard:account',
                                          key: Math.floor(Math.random() * 1000000),
                                          theme: 'slds-theme_success'
                                      };
                                  })
                          };
                      })
            };
            console.log('getter  result: ' + JSON.stringify(result));
            return result;
        });
    }
    get openUserThreads() {
        return this.openThreadsByType('HOT_BRUKER-FORMIDLER');
    }
    get userThreadTabLabel() {
        return this.tabLabelByType('HOT_BRUKER-FORMIDLER');
    }
    get openOrdererThreads() {
        return this.openThreadsByType('HOT_BESTILLER-FORMIDLER');
    }
    get ordererThreadTabLabel() {
        return this.tabLabelByType('HOT_BESTILLER-FORMIDLER');
    }
    get openUserInterpreterThreads() {
        return this.openThreadsByType('HOT_BRUKER-TOLK');
    }
    get userInterpreterThreadTabLabel() {
        return this.tabLabelByType('HOT_BRUKER-TOLK');
    }
    get openInterpreterInterpreterThreads() {
        return this.openThreadsByType('HOT_TOLK-TOLK');
    }
    get interpreterInterpreterThreadTabLabel() {
        return this.tabLabelByType('HOT_TOLK-TOLK');
    }
    get openInterpreterThreads() {
        return this.openThreadsByType('HOT_TOLK-FORMIDLER');
    }
    get interpreterThreadTabLabel() {
        return this.tabLabelByType('HOT_TOLK-FORMIDLER');
    }
    get openOfficeThreads() {
        return this.openThreadsByType('HOT_TOLK-RESSURSKONTOR');
    }
    get officeThreadTabLabel() {
        return this.tabLabelByType('HOT_TOLK-RESSURSKONTOR');
    }
    openThreadsByType(type) {
        if (!this.threadsAndParticipants) {
            console.log('threadsAndParticipants is null');
            return null;
        }
        if (!Object.keys(this.threadsAndParticipants).includes(type)) {
            console.log(`Cannot find ${type} in threadsAndParticipants`);
            return null;
        }
        if (!this.threadsAndParticipants[type] || !(Object.keys(this.threadsAndParticipants[type]).length > 0)) {
            console.log(`No threads found for ${type}`);
            return null;
        }
        return Object.keys(this.threadsAndParticipants[type]).map((threadId) => {
            return {
                Id: threadId //this.threadsAndParticipants[type][threadId]
            };
        });
    }
    tabLabelByType(threadType) {
        return this.openThreadsByType(threadType) ? this.tabLabels[threadType].open : this.tabLabels[threadType].new;
    }
    summaryTabHandler() {
        console.log('summaryTabHandler');
        this.getThreadAndParticipants();
    }
    userThreadTabHandler() {
        console.log('userThreadTabHandler');
        this.tabHandlerByType('HOT_BRUKER-FORMIDLER');
    }
    ordererThreadTabHandler() {
        console.log('ordererThreadTabHandler');
        this.tabHandlerByType('HOT_BESTILLER-FORMIDLER');
    }
    userInterpreterThreadTabHandler() {
        console.log('userInterpreterThreadTabHandler');
        this.tabHandlerByType('HOT_BRUKER-TOLK');
    }
    interpreterInterpreterThreadTabHandler() {
        console.log('interpreterInterpreterThreadTabHandler');
        this.tabHandlerByType('HOT_TOLK-TOLK');
    }
    interpreterThreadTabHandler() {
        console.log('interpreterThreadTabHandler');
        this.tabHandlerByType('HOT_TOLK-FORMIDLER');
    }
    officeThreadTabHandler() {
        console.log('officeThreadTabHandler');
        this.tabHandlerByType('HOT_TOLK-RESSURSKONTOR');
    }
    tabHandlerByType(threadType) {
        console.log('tabHandlerByType for type: ' + threadType);
        this.runningThreadCreate = true; // this one for test
        if (this.openThreadsByType(threadType)) {
            this.runningThreadCreate = false;
            let threadCmp = this.template.querySelector(this.threadCmpMap[threadType]);
            if (threadCmp) {
                console.log('thread component found');
                threadCmp.focusOnInput();
            } else {
                console.log('thread component not found');
            }
        } else {
            this.runningThreadCreate = true;
            console.log('create new thread here.');
            this.newThreadWithType(threadType);
        }
    }
    newThreadWithType(threadType) {
        if (this.accountId == undefined) {
            getAccountOnWorkOrder({ recordId: this.recordId })
                .then((result) => {
                    this.accountId = result;
                    createThread({ recordId: this.recordId, accountId: this.accountId, type: threadType })
                        .then(() => {
                            this.getThreadAndParticipants();
                            // TODO: what shoudl trigges here?
                        })
                        .catch((error) => {
                            if (
                                this.objectApiName === 'HOT_InterestedResource__c' &&
                                error.body.message === 'thread exist'
                            ) {
                                this.interestedResourceIsAssigned = true;
                            } else if (
                                this.objectApiName === 'ServiceAppointment' &&
                                error.body.message === 'no employee'
                            ) {
                                this.noAssignedResource = true;
                            } else {
                                console.log(error);
                            }
                        });
                })
                .catch((error) => {
                    console.log(error);
                })
                .finally(() => {
                    this.runningThreadCreate = false;
                });
        } else {
            createThread({ recordId: this.recordId, accountId: this.accountId, type: threadType })
                .then(() => {
                    this.getThreadAndParticipants();
                })
                .catch((error) => {
                    console.log(error);
                })
                .finally(() => {
                    this.runningThreadCreate = false;
                });
        }
    }
    handleTabChange() {
        console.log('handleTabChange');
    }
}
