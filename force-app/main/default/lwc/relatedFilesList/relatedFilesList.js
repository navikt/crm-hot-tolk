import { LightningElement, api, track, wire } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RelatedFilesListController.getContentDocuments';

export default class RelatedFilesList extends LightningElement {
    @api selectedRows = [];
    @api recordId;

    renderedCallback() {
        console.log('this.recordId: ' + this.recordId);
    }
    @track contentDocuments = [];
    @wire(getContentDocuments, { recordId: '$recordId' })
    wiredGetContentDocuments(result) {
        console.log(JSON.stringify(result));
        if (result.data) {
            console.log(JSON.stringify(result.data));
            this.contentDocuments = result.data;
        }
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    @track columns = [
        {
            label: 'Id',
            fieldName: 'Id',
            type: 'text',
            sortable: true
        }
    ];
}
