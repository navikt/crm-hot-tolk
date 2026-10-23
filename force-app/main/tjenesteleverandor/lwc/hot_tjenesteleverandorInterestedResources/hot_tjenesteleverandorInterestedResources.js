import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import interestedResourcesOfServiceAppointment from '@salesforce/apex/HOT_TLServiceResourceController.interestedResourcesOfServiceAppointment';

export default class Hot_tjenesteleverandorInterestedResources extends LightningElement {
    @api recordId;
    routeRecordId;
    interestedResources = [];
    interestedResourcesError;

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        this.routeRecordId = pageReference?.state?.c__recordId;
    }

    get effectiveRecordId() {
        return this.recordId || this.routeRecordId;
    }

    @wire(interestedResourcesOfServiceAppointment, { saID: '$effectiveRecordId' })
    wiredResources({ data, error }) {
        if (data) {
            this.interestedResources = data.map((resource) => ({
                ...resource,
                isInterested: resource.Status__c === 'Interested'
            }));
            this.interestedResourcesError = undefined;
        } else if (error) {
            this.interestedResources = [];
            this.interestedResourcesError = error;
        }
    }

    handleAssignClick(event) {
        alert('funksjonalitet ikke laget');
        console.log('Assign resource', {
            serviceAppointmentId: this.effectiveRecordId,
            serviceResourceId: event.currentTarget.dataset.serviceResourceId
        });
    }
}
