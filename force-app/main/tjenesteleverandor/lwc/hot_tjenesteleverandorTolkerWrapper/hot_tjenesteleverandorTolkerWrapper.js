import { LightningElement, wire } from 'lwc';
import { columns } from './columns';
import getServiceResources from '@salesforce/apex/HOT_TjenesteleverandorListController.getServiceResources';

export default class Hot_tjenesteleverandorTolkerWrapper extends LightningElement {

    tolkerList = [];
    columns = columns;
    dataLoader = true;
    
    error = null;

    @wire(getServiceResources)
    wiredServiceResources({ error, data }) {
        if (data) {
            this.tolkerList = data.map(item => ({ 
                ...item,
                Region: item.HOT_ServiceTerritory__r?.Name ?? "Ikke tilgjengelig",
                IsActiveLabel: item.IsActive ? 'Ja' : 'Nei'
            }));
            this.error = null;
            this.dataLoader = false;
        } else if (error) {
            console.error('Error fetching service resources:', error);
            this.error = error;
            this.dataLoader = false;
            this.tolkerList = [];
        }
    }

    goToRecordDetails(event) {
        const record = this.tolkerList.find(tolk => tolk.Id === event.detail.Id);
        console.log('Navigating to record details for record:', record);
    }

    get hasNoResult() {
        return !this.error && !this.dataLoader && this.tolkerList.length === 0;
    }

    get hasResult() {
        return this.tolkerList.length > 0 && !this.dataLoader;
    }

    get hasError()  { 
        return !this.dataLoader && Boolean(this.error); 
    }

    get errorMessage() { 
        return this.error?.body?.message ?? 'Kunne ikke hente tolker.'; 
    }
}