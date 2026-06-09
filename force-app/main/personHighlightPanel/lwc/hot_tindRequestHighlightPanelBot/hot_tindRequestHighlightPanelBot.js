import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { notifyRecordUpdateAvailable, getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import HOT_REQUEST_OBJECT from '@salesforce/schema/HOT_Request__c';
import IS_DELETED_FIELD from '@salesforce/schema/HOT_Request__c.IsDeleted';
import Hot_flowModal from 'c/hot_flowModal';

import hasFormidlerAccess from '@salesforce/customPermission/HOT_AccessToFormidlerActions';

export default class hot_tindRequestHighlightPanelBot extends NavigationMixin(LightningElement) {
    @api recordId;

    canEdit = false;
    canClone = false;
    objectInfo;
    record;

    @wire(getObjectInfo, { objectApiName: HOT_REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
            this.updateButtonVisibility();
        } else if (error) {
            console.error('Error fetching object info:', error);
            this.canEdit = false;
            this.canClone = false;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [IS_DELETED_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
            this.updateButtonVisibility();
        } else if (error) {
            console.error('Error fetching record:', error);
            this.canEdit = false;
            this.canClone = false;
        }
    }

    updateButtonVisibility() {
        if (!this.objectInfo || !this.record) {
            return;
        }

        const isDeleted = this.record.fields?.IsDeleted?.value === true;
        this.canEdit = this.objectInfo.updateable === true && !isDeleted;
        this.canClone = this.objectInfo.createable === true;
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
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

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
            size: 'small',
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
            size: 'small',
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
            size: 'small',
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
            size: 'small',
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
            size: 'small',
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
