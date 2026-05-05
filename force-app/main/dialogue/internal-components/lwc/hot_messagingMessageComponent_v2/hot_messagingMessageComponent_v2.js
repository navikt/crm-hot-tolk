import { LightningElement, api, wire, track } from 'lwc';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThreadDispatcher';
import getUserContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getThreadsAndParticipants from '@salesforce/apex/HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes';
import getAccountOnRequest from '@salesforce/apex/HOT_MessageHelper.getAccountOnRequest';
import getRequestInformation from '@salesforce/apex/HOT_MessageHelper.getRequestInformationAndAccessCheck';
import getWorkOrderInformation from '@salesforce/apex/HOT_MessageHelper.getWorkOrderInformationAndAccessCheck';
import getWageClaimInformation from '@salesforce/apex/HOT_MessageHelper.getWageClaimInformationAndAccessCheck';
import getServiceAppointmentInformation from '@salesforce/apex/HOT_MessageHelper.getServiceAppointmentInformationAndAccessCheck';
import getInterestedResourceInformation from '@salesforce/apex/HOT_MessageHelper.getInterestedResourceInformationAndAccessCheck';
import getAccountOnWorkOrder from '@salesforce/apex/HOT_MessageHelper.getAccountOnWorkOrder';
import getThreadInformation from '@salesforce/apex/HOT_ThreadDetailController.getThreadDetails';
import setLastMessageFrom from '@salesforce/apex/HOT_MessageHelper.setLastMessageFrom';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';

export default class hot_messagingMessageComponent extends LightningElement {
    relatedObjectId;
    isThreadSummaryLoaded = false;
    defaultActiveTab = 'tab1';
    messageInputShow = true;
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
    noAccess = false;
    noAccessMessage = 'Du har ikke tilgang til samtaler';

    messageTemplates = {
        'HOT_TOLK-TOLK': '',
        'HOT_BRUKER-TOLK': '',
        'HOT_BESTILLER-FORMIDLER': '',
        'HOT_BRUKER-FORMIDLER': '',
        'HOT_TOLK-RESSURSKONTOR': '',
        'HOT_TOLK-FORMIDLER': ''
    };

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
    threadMockCmpMap = {
        'HOT_TOLK-TOLK': '[data-int-int-thread-mock]',
        'HOT_BRUKER-TOLK': '[data-user-int-thread-mock]',
        'HOT_BESTILLER-FORMIDLER': '[data-orderer-thread-mock]',
        'HOT_BRUKER-FORMIDLER': '[data-user-thread-mock]',
        'HOT_TOLK-RESSURSKONTOR': '[data-office-thread-mock]',
        'HOT_TOLK-FORMIDLER': '[data-int-thread-mock]'
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
    tabByThreadTypesMap = {
        'HOT_TOLK-TOLK': 'tab5',
        'HOT_BRUKER-TOLK': 'tab4',
        'HOT_BESTILLER-FORMIDLER': 'tab3',
        'HOT_BRUKER-FORMIDLER': 'tab2',
        'HOT_TOLK-RESSURSKONTOR': 'tab7',
        'HOT_TOLK-FORMIDLER': 'tab6'
    };
    @track
    threadTypesOfInterest = [];
    @track threadsAndParticipants;

    @track errorMessage;
    @track noAssignedResource = false;
    @track interestedResourceIsAssigned = false;
    threadParticipants;

    userContactId;

    @api recordId;
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

    renderedCallback() {}
    connectedCallback() {
        this.relatedObjectId = this.recordId;
        if (this.objectApiName === 'HOT_Request__c') {
            getRequestInformation({ recordId: this.recordId })
                .then((result) => {
                    if (result.IsAccountEqualOrderer__c == true) {
                        this.threadTypesOfInterest = ['HOT_BRUKER-FORMIDLER'];
                    } else if (result.Account__c == null && result.Orderer__c != null) {
                        this.threadTypesOfInterest = ['HOT_BESTILLER-FORMIDLER'];
                    } else if (result.Account__c != null && result.Orderer__c == null) {
                        this.threadTypesOfInterest = ['HOT_BRUKER-FORMIDLER'];
                    } else {
                        this.threadTypesOfInterest = ['HOT_BRUKER-FORMIDLER', 'HOT_BESTILLER-FORMIDLER'];
                    }
                })
                .catch((error) => {
                    if (error?.body?.message == 'No access') {
                        this.noAccess = true;
                        this.noAccessMessage = 'Du har ikke tilgang til samtaler på denne forespørselen';
                    }
                    console.log(error);
                })
                .finally(() => {
                    this.getThreadAndParticipants();
                });
        } else if (this.objectApiName === 'WorkOrder') {
            getWorkOrderInformation({ recordId: this.recordId })
                .then((result) => {
                    if (result.HOT_TotalNumberOfInterpreters__c > 1) {
                        this.threadTypesOfInterest = ['HOT_TOLK-TOLK', 'HOT_BRUKER-TOLK'];
                    } else {
                        this.threadTypesOfInterest = ['HOT_BRUKER-TOLK'];
                    }

                    // work orders with status canceled should not show message input,
                    // but user should be able to see existing messages for 48 hours after cancellation
                    if (this.threadTypesOfInterest.includes('HOT_BRUKER-TOLK') && result.Status === 'Canceled') {
                        this.messageInputShow = false;
                    }
                })
                .catch((error) => {
                    if (error?.body?.message == 'No access') {
                        this.noAccess = true;
                        this.noAccessMessage = 'Du har ikke tilgang til samtaler på denne arbeidsordren';
                    }
                    console.log(error);
                })
                .finally(() => {
                    this.getThreadAndParticipants();
                });
        } else if (this.objectApiName === 'HOT_WageClaim__c') {
            getWageClaimInformation({ recordId: this.recordId })
                .then(() => {
                    this.threadTypesOfInterest = ['HOT_TOLK-RESSURSKONTOR'];
                })
                .catch((error) => {
                    if (error?.body?.message == 'No access') {
                        this.noAccess = true;
                        this.noAccessMessage = 'Du har ikke tilgang til samtaler på dette lønnskravet';
                    }
                    console.log(error);
                })
                .finally(() => {
                    this.getThreadAndParticipants();
                });
        } else if (this.objectApiName === 'ServiceAppointment') {
            getServiceAppointmentInformation({ recordId: this.recordId })
                .then((result) => {
                    this.threadTypesOfInterest = ['HOT_TOLK-FORMIDLER'];
                })
                .catch((error) => {
                    if (error?.body?.message == 'No access') {
                        this.noAccess = true;
                        this.noAccessMessage = 'Du har ikke tilgang til samtaler på dette oppdraget';
                    }
                    console.log(error);
                })
                .finally(() => {
                    this.getThreadAndParticipants();
                });
        } else if (this.objectApiName === 'HOT_InterestedResource__c') {
            getInterestedResourceInformation({ recordId: this.recordId })
                .then(() => {
                    this.threadTypesOfInterest = ['HOT_TOLK-FORMIDLER'];
                })
                .catch((error) => {
                    if (error?.body?.message == 'No access') {
                        this.noAccess = true;
                        this.noAccessMessage = 'Du har ikke tilgang til samtaler på denne interesserte ressursen';
                    }
                    console.log(error);
                })
                .finally(() => {
                    this.getThreadAndParticipants();
                });
        } else if (this.objectApiName === 'Thread__c') {
            getThreadInformation({ recordId: this.recordId })
                .then((result) => {
                    this.relatedObjectId = result.CRM_Related_Object__c ?? result.Id;
                    this.threadTypesOfInterest = [result.CRM_Thread_Type__c];
                })
                .catch((error) => {
                    if (error?.body?.message == 'No access') {
                        this.noAccess = true;
                        this.noAccessMessage = 'Du har ikke tilgang til samtaler på denne samtalen';
                    }
                    console.log(error);
                })
                .finally(() => {
                    this.getThreadAndParticipants();
                });
        } else {
            console.log('Not supportet object for messaging component');
        }
    }

    async getThreadAndParticipants() {
        if (this.threadTypesOfInterest == null || this.threadTypesOfInterest.length === 0) {
            this.isThreadSummaryLoaded = true;
            console.log('No thread types of interest defined, skipping getThreadsAndParticipants');
            return;
        }
        try {
            const result = await getThreadsAndParticipants({
                relatedObjectId: this.relatedObjectId,
                threadTypesOfInterest: this.threadTypesOfInterest
            });
            this.threadsAndParticipants = result;
        } catch (error) {
            console.log('Error getting threads and participants: ');
            console.log(error);
        }
        this.isThreadSummaryLoaded = true;
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
    get userMessageTemplate() {
        return this.messageTemplates['HOT_BRUKER-FORMIDLER'];
    }
    get ordererMessageTemplate() {
        return this.messageTemplates['HOT_BESTILLER-FORMIDLER'];
    }
    get interpreterMessageTemplate() {
        return this.messageTemplates['HOT_TOLK-FORMIDLER'];
    }
    get userInterpreterMessageTemplate() {
        return this.messageTemplates['HOT_BRUKER-TOLK'];
    }
    get interpreterInterpreterMessageTemplate() {
        return this.messageTemplates['HOT_TOLK-TOLK'];
    }
    get officeMessageTemplate() {
        return this.messageTemplates['HOT_TOLK-RESSURSKONTOR'];
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
                    return participant.hasRead;
                })
                .map((participant) => {
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
            return result;
        });
    }

    get showUserThreadTab() {
        return this.threadTypesOfInterest.includes('HOT_BRUKER-FORMIDLER') && this.isThreadSummaryLoaded;
    }
    get showOrderThreadTab() {
        return this.threadTypesOfInterest.includes('HOT_BESTILLER-FORMIDLER') && this.isThreadSummaryLoaded;
    }
    get showUserInterpreterThreadTab() {
        return this.threadTypesOfInterest.includes('HOT_BRUKER-TOLK') && this.isThreadSummaryLoaded;
    }
    get showInterpreterInterpreterThreadTab() {
        return this.threadTypesOfInterest.includes('HOT_TOLK-TOLK') && this.isThreadSummaryLoaded;
    }
    get showInterpreterThreadTab() {
        return this.threadTypesOfInterest.includes('HOT_TOLK-FORMIDLER') && this.isThreadSummaryLoaded;
    }
    get showOfficeThreadTab() {
        return this.threadTypesOfInterest.includes('HOT_TOLK-RESSURSKONTOR') && this.isThreadSummaryLoaded;
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
    get summaryLoading() {
        return !this.isThreadSummaryLoaded;
    }
    get activeTab() {
        const openThreadType = this.findOpenThread();
        if (openThreadType) {
            return this.tabByThreadTypesMap[openThreadType];
        }
        if (this.threadTypesOfInterest && this.threadTypesOfInterest.length > 0) {
            return this.tabByThreadTypesMap[this.threadTypesOfInterest[0]];
        }
        return this.defaultActiveTab;
    }
    findOpenThread() {
        if (!this.threadsAndParticipants || !this.threadTypesOfInterest) {
            console.log('threadsAndParticipants or threadTypesOfInterest is null');
            return null;
        }
        return this.threadTypesOfInterest.find((type) => {
            return this.openThreadsByType(type) != null;
        });
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
        this.getThreadAndParticipants();
    }
    userThreadTabHandler() {
        this.tabHandlerByType('HOT_BRUKER-FORMIDLER');
    }
    ordererThreadTabHandler() {
        this.tabHandlerByType('HOT_BESTILLER-FORMIDLER');
    }
    userInterpreterThreadTabHandler() {
        this.tabHandlerByType('HOT_BRUKER-TOLK');
    }
    interpreterInterpreterThreadTabHandler() {
        this.tabHandlerByType('HOT_TOLK-TOLK');
    }
    interpreterThreadTabHandler() {
        this.tabHandlerByType('HOT_TOLK-FORMIDLER');
    }
    officeThreadTabHandler() {
        this.tabHandlerByType('HOT_TOLK-RESSURSKONTOR');
    }
    tabHandlerByType(threadType) {
        if (this.openThreadsByType(threadType)) {
            let threadCmp = this.template.querySelector(this.threadCmpMap[threadType]);
            if (threadCmp) {
                threadCmp.focusOnInput();
            }
        } else {
            let threadMockCmp = this.template.querySelector(this.threadMockCmpMap[threadType]);
            if (threadMockCmp) {
                threadMockCmp.focusOnInput();
            }
            /*
            this.newThreadWithType(threadType);
            */
        }
    }
    handleCreateUserThreadWithMessage(event) {
        this.newThreadWithTypeAndMessage('HOT_BRUKER-FORMIDLER', event.detail);
    }
    handleCreateOrdererThreadWithMessage(event) {
        this.newThreadWithTypeAndMessage('HOT_BESTILLER-FORMIDLER', event.detail);
    }
    handleCreateUserInterpreterThreadWithMessage(event) {
        this.newThreadWithTypeAndMessage('HOT_BRUKER-TOLK', event.detail);
    }
    handleCreateInterpreterInterpreterThreadWithMessage(event) {
        this.newThreadWithTypeAndMessage('HOT_TOLK-TOLK', event.detail);
    }
    handleCreateInterpreterThreadWithMessage(event) {
        this.newThreadWithTypeAndMessage('HOT_TOLK-FORMIDLER', event.detail);
    }
    handleCreateOfficeThreadWithMessage(event) {
        this.newThreadWithTypeAndMessage('HOT_TOLK-RESSURSKONTOR', event.detail);
    }
    async newThreadWithTypeAndMessage(threadType, message) {
        this.runningThreadCreate = true;
        let thread;
        if (this.accountId == undefined) {
            try {
                this.accountId = await getAccountOnWorkOrder({ recordId: this.recordId });
            } catch (error) {
                console.error(JSON.stringify(error), error);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Feil ved opprettelse av samtale',
                        message: 'Samtalen kunne ikke bli opprettet',
                        variant: 'error'
                    })
                );
                this.runningThreadCreate = false;
                return;
            }
        }
        try {
            thread = await createThread({
                recordId: this.recordId,
                accountId: this.accountId,
                type: threadType
            });
        } catch (error) {
            if (this.objectApiName === 'HOT_InterestedResource__c' && error.body.message === 'thread exist') {
                this.interestedResourceIsAssigned = true;
            } else if (this.objectApiName === 'ServiceAppointment' && error.body.message === 'no employee') {
                this.noAssignedResource = true;
            } else {
                console.error(JSON.stringify(error), error);
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Feil ved opprettelse av samtale',
                    message: 'Samtalen kunne ikke bli opprettet',
                    variant: 'error'
                })
            );
            this.runningThreadCreate = false;
            return;
        }
        try {
            const fields = message;
            fields.CRM_Thread__c = thread.Id;
            await createRecord({
                apiName: 'Message__c',
                fields: fields
            });
        } catch (error) {
            this.messageTemplates[threadType] = message.CRM_Message_Text__c;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Feil ved sending av melding',
                    message: 'Meldingen kunne ikke bli sendt',
                    variant: 'error'
                })
            );
            console.error(JSON.stringify(error), error);
        }
        setLastMessageFrom({ threadId: thread.Id, fromContactId: 'ansatt/formidler' })
            .then(() => {
                console.log('Last message from set to contact');
            })
            .catch((error) => {
                console.error('Error setting last message from: ', JSON.stringify(error), error);
            });
        try {
            await this.getThreadAndParticipants();
        } catch (error) {
            console.error(JSON.stringify(error), error);
        }
        this.runningThreadCreate = false;
    }
}
