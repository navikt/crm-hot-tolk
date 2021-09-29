import { LightningElement, api, wire, track } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RelatedFilesListController.getContentDocuments';
import createBaseUrlLink from '@salesforce/apex/HOT_RelatedFilesListController.createBaseUrlLink';

export default class hot_recordFiles extends LightningElement {
    @api recordId;
    @track baseUrl;

    connectedCallback() {
        createBaseUrlLink().then((result) => {
            this.baseUrl = result;
        });
    }

    contentDocuments = [];
    contentDocumentsEmpty = true;
    @wire(getContentDocuments, { recordId: '$recordId' })
    wiredgetContentDocuments(result) {
        if (result.data) {
            this.contentDocuments = result.data.map((item) => ({
                ...item,
                downloadLink: this.baseUrl + item.Id
            }));
            this.contentDocumentsEmpty = this.contentDocuments.length === 0 ? true : false;
        } else {
            this.contentDocumentsEmpty = true;
        }
    }
}
