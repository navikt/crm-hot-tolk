import { LightningElement, wire } from 'lwc';
import { columns } from './columns';
import getServiceResources from '@salesforce/apex/HOT_TjenesteleverandorListController.getServiceResources';

export default class Hot_tjenesteleverandorTolkerWrapper extends LightningElement {

    tolkerList = [];
    columns = columns;

    @wire(getServiceResources)
    wiredServiceResources({ error, data }) {
        if (data) {
            this.tolkerList = data;
        } else if (error) {
            console.error('Error fetching service resources:', error);
        }
    }

    goToRecordDetails(event) {
        const record = this.tolkerList.find(tolk => tolk.Id === event.detail.Id);
        console.log('Navigating to record details for record:', record);
    }
}