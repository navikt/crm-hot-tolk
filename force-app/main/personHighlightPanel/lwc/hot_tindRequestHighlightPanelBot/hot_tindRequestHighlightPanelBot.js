import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange, getRecordUi } from 'lightning/uiRecordApi';
import Hot_flowModal from 'c/hot_flowModal';

import hasFormidlerAccess from '@salesforce/customPermission/HOT_AccessToFormidlerActions';

export default class hot_tindRequestHighlightPanelBot extends NavigationMixin(LightningElement) {
    @api recordId;

    canEdit = false;
    canClone = false;

    @wire(getRecordUi, {
        recordIds: '$recordId',
        layoutTypes: 'Full',
        modes: 'View'
    })
    wiredRecordUi({ error, data }) {
        if (data) {
            const record = data.records[this.recordId];
            // objectInfos is at the top level, keyed by object API name
            const objectInfo = data.objectInfos?.['HOT_Request__c'];
            console.log('Record UI data:', objectInfo);
            if (record && objectInfo) {
                // Check if user can edit (updateable and not deleted)
                this.canEdit = objectInfo.updateable === true && record.fields?.IsDeleted?.value !== true;
                // Check if user can clone (createable permission)
                this.canClone = objectInfo.createable === true;
            }
        } else {
            console.error('Error fetching record UI:', error);
            this.canEdit = false;
            this.canClone = false;
        }
    }

    get showEditButton() {
        return this.canEdit;
    }

    get showCloneButton() {
        return this.canClone;
    }

    handleEditRequest() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HOT_Request__c',
                actionName: 'edit'
            }
        });
    }
    handleClone() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HOT_Request__c',
                actionName: 'clone'
            }
        });
    }
    dispatchRefreshEvent() {
        // Notify Lightning Data Service that the record has changed
        // This will refresh all standard components on the record page
        getRecordNotifyChange([{ recordId: this.recordId }]);

        // Dispatch custom event to direct parent to refresh data
        // bubbles: false - event doesn't need to bubble beyond parent
        // composed: false - event doesn't need to cross shadow DOM (parent handles it directly)
        this.dispatchEvent(
            new CustomEvent('refreshrequest', {
                bubbles: false,
                composed: false
            })
        );
    }

    async handleCreateWorkOrder() {
        const result = await Hot_flowModal.open({
            size: 'large',
            flowApiName: 'HOT_CreateWorkOrder',
            flowLabel: 'Opprett arbeidsordre',
            recordId: this.recordId
        });

        // Refresh parent component if flow completed successfully
        if (result === 'FINISHED' || result === 'FINISHED_SCREEN') {
            this.dispatchRefreshEvent();
        }
    }
    async handleScheduleServiceAppointments() {
        const result = await Hot_flowModal.open({
            size: 'large',
            flowApiName: 'Auto_Schedule_Service_Appointments',
            flowLabel: 'Automatisk planlegging',
            recordId: this.recordId
        });

        if (result === 'FINISHED' || result === 'FINISHED_SCREEN') {
            this.dispatchRefreshEvent();
        }
    }
    async handleUpdateChildsFromRequest() {
        const result = await Hot_flowModal.open({
            size: 'large',
            flowApiName: 'HOT_UpdateChildsFromRequest',
            flowLabel: 'Oppdater felter til oppdrag',
            recordId: this.recordId
        });

        if (result === 'FINISHED' || result === 'FINISHED_SCREEN') {
            this.dispatchRefreshEvent();
        }
    }
    async handleDeleteContentDocument() {
        const result = await Hot_flowModal.open({
            size: 'large',
            flowApiName: 'HOT_DeleteContentDocument',
            flowLabel: 'Slett filer',
            recordId: this.recordId
        });

        if (result === 'FINISHED' || result === 'FINISHED_SCREEN') {
            this.dispatchRefreshEvent();
        }
    }
    async handleMessageToDispatcher() {
        const result = await Hot_flowModal.open({
            size: 'large',
            flowApiName: 'HOT_AddCommentToRequest',
            flowLabel: 'Beskjed til formidler',
            recordId: this.recordId
        });

        if (result === 'FINISHED' || result === 'FINISHED_SCREEN') {
            this.dispatchRefreshEvent();
        }
    }
    get showFormidlerActions() {
        return hasFormidlerAccess;
    }
}
