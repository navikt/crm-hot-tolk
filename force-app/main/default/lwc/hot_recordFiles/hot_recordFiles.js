import { LightningElement, api, wire, track } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RelatedFilesListController.getContentDocuments';
import createBaseUrlLink from '@salesforce/apex/HOT_RelatedFilesListController.createBaseUrlLink';

export default class hot_recordFiles extends LightningElement {
    @api recordId;
    @api title;

    contentDocuments = [];
    contentDocumentsEmpty = true;

    @wire(getContentDocuments, { recordId: '$recordId' })
    async wiredgetContentDocuments(result) {
        if (result.data) {
            const url = await createBaseUrlLink();
            this.contentDocuments = result.data.map((item) => ({
                ...item,
                downloadLink: url + item.Id
            }));
            this.contentDocumentsEmpty = this.contentDocuments.length === 0 ? true : false;
        } else {
            this.contentDocumentsEmpty = true;
        }
    }
}
