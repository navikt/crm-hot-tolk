import { LightningElement, api, wire, track } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RelatedFilesListController.getContentDocuments';
import createBaseUrlLink from '@salesforce/apex/HOT_RelatedFilesListController.createBaseUrlLink';

// TODO: Rename to hot_recordFiles
export default class RecordFiles extends LightningElement {
    @api recordId;

    contentDocuments = [];
    contentDocumentsEmpty = true;
    @track baseUrl;

    connectedCallback() {
        createBaseUrlLink().then((result) => {
            this.baseUrl = result;
        });
    }

    @wire(getContentDocuments, { recordId: '$recordId' })
    wiredgetContentDocuments(result) {
        if (result.data) {
            console.log(JSON.stringify(result.data));
            this.contentDocuments = result.data.map((item) => ({
                ...item,
                downloadLink: this.baseUrl + item.Id
            }));
            this.contentDocumentsEmpty = false;
        } else {
            this.contentDocumentsEmpty = true;
        }
    }
}
