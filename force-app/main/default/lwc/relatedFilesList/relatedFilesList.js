import { LightningElement, api, track, wire } from 'lwc';
import getContentDocuments from '@salesforce/apex/RecordFilesControllerWithSharing.getContentDocuments';

export default class RelatedFilesList extends LightningElement {
    @api selectedRows = [];
    @api recordId;
    @track contentDocuments = [];

    @wire(getContentDocuments, { recordId: '$recordId', isGetAll: true })
    wiredGetContentDocuments(result) {
        if (result.data) {
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
