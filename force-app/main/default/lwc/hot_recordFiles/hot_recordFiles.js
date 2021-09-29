import { LightningElement, api, wire } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RelatedFilesListController.getContentDocuments';
import createBaseUrlLink from '@salesforce/apex/HOT_RelatedFilesListController.createBaseUrlLink';
import { setDefaultValue } from 'c/componentHelperClass';

export default class hot_recordFiles extends LightningElement {
    @api recordId;
    @api title;

    contentDocuments = [];
    contentDocumentsEmpty = true;

    get defaultTitle() {
        return setDefaultValue(this.title, 'Vedlegg');
    }

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
