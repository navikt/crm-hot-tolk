import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

export default class Hot_serviceProviderInterpreterDetails extends NavigationMixin(LightningElement) {

    @wire(CurrentPageReference)
        handlePageReference(pageReference) {
            this.routeRecordId = pageReference?.state?.c__recordId;
        }

    get recordId() {
        return this.routeRecordId;
    }
}