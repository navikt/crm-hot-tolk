import { LightningElement, api, track, wire } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RelatedFilesListController.getContentDocuments';
import { sortList, getMobileSortingOptions } from 'c/sortController';

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
            label: 'Tittel',
            fieldName: 'Title',
            type: 'text'
        },
        {
            label: 'Filtype',
            fieldName: 'FileType',
            type: 'text'
        },
        {
            label: 'Opprettelsesdato',
            fieldName: 'CreatedDate',
            type: 'date',
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        }
    ];
}
