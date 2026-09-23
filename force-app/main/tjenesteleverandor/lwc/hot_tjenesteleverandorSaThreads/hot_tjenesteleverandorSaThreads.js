import { LightningElement, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id';
import getSARelatedThreads from '@salesforce/apex/HOT_TLThreadlistController.getSARelatedThreads';
import getParticipants from '@salesforce/apex/HOT_ThreadParticipants.getParticipants';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThreadDispatcher';
import setLastMessageFrom from '@salesforce/apex/HOT_MessageHelper.setLastMessageFrom';

export default class Hot_tjenesteleverandorSaThreads extends LightningElement {
    _serviceAppointmentId;
    _threadConfigurations = [];
    requestId = 0;
    threadCards = [];

    @api
    get serviceAppointmentId() {
        return this._serviceAppointmentId;
    }

    set serviceAppointmentId(value) {
        this._serviceAppointmentId = value;
        void this.loadThreads();
    }

    @api
    get threadConfigurations() {
        return this._threadConfigurations;
    }

    set threadConfigurations(value) {
        this._threadConfigurations = Array.isArray(value) ? value : [];
        void this.loadThreads();
    }

    async loadThreads() {
        const serviceAppointmentId = this.serviceAppointmentId;
        const configurations = this.threadConfigurations;
        const currentRequestId = ++this.requestId;

        if (!serviceAppointmentId || configurations.length === 0) {
            this.threadCards = [];
            return;
        }

        try {
            const threads = await getSARelatedThreads({ serviceAppointmentId });
            const cards = await Promise.all(
                configurations.map(async (configuration) => {
                    const thread = (threads ?? []).find(
                        (candidate) => (candidate.CRM_Thread_Type__c || candidate.CRM_Type__c) === configuration.type
                    );
                    const participants = thread ? await getParticipants({ threadId: thread.Id }) : [];

                    return this.toThreadCard(configuration, thread, participants);
                })
            );

            if (currentRequestId === this.requestId) {
                this.threadCards = cards;
            }
        } catch (error) {
            if (currentRequestId === this.requestId) {
                this.threadCards = configurations.map((configuration) => this.toThreadCard(configuration, null, []));
            }
            console.error('Could not load related threads', JSON.stringify(error), error);
        }
    }

    toThreadCard(configuration, thread, participants) {
        const participantLabels = this.toParticipantLabels(participants);
        const readParticipantLabels = this.toReadParticipantLabels(participants);

        return {
            ...configuration,
            thread,
            participants: participantLabels,
            readParticipants: readParticipantLabels,
            hasThread: Boolean(thread),
            hasReadParticipants: readParticipantLabels.length > 0
        };
    }

    toParticipantLabels(participants) {
        return (participants ?? []).map((participant) => ({
            id: participant.userId || participant.name || participant.role,
            label: participant.role ? `${participant.name} (${participant.role})` : participant.name
        }));
    }

    toReadParticipantLabels(participants) {
        return (participants ?? [])
            .filter((participant) => participant.hasRead)
            .map((participant) => ({
                id: participant.userId || participant.name || participant.role,
                label: participant.role ? `${participant.name} (${participant.role})` : participant.name
            }));
    }

    async handleCreateThreadWithMessage(event) {
        const threadType = event.currentTarget.dataset.threadType;
        if (!this.serviceAppointmentId || !threadType) {
            return;
        }

        try {
            const thread = await createThread({
                recordId: this.serviceAppointmentId,
                accountId: userId,
                type: threadType
            });

            await createRecord({
                apiName: 'Message__c',
                fields: {
                    ...event.detail,
                    CRM_Thread__c: thread?.Id
                }
            });

            setLastMessageFrom({ threadId: thread.Id, fromContactId: userId }).catch((error) => {
                console.error('Error setting last message from: ', JSON.stringify(error), error);
            });

            await this.loadThreads();
        } catch (error) {
            console.error('Could not create related thread', JSON.stringify(error), error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Feil ved opprettelse av samtale',
                    message: 'Samtalen kunne ikke bli opprettet',
                    variant: 'error'
                })
            );
        }
    }
}
