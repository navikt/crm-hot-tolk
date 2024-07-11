import { LightningElement, api, wire, track } from 'lwc';
import getContentDocuments from '@salesforce/apex/HOT_RecordFilesControllerWithSharing.getContentDocuments';
import getBaseDownloadUrl from '@salesforce/apex/HOT_RecordFilesControllerWithSharing.getBaseDownloadUrl';
import deleteFilesOnRecord from '@salesforce/apex/HOT_RecordFilesControllerWithSharing.deleteFilesOnRecord';
import getOnlyMyContentDocuments from '@salesforce/apex/HOT_RecordFilesControllerWithSharing.getOnlyMyContentDocuments';
import { setDefaultValue, convertStringToBoolean } from 'c/componentHelperClass';
import { refreshApex } from '@salesforce/apex';
export default class hot_recordFilesWithSharing extends LightningElement {
    @api recordId;
    @api title;
    @api files = [];
    @api isGetAll = false;
    @api isDeleteOption = false;
    @api deleteFileOnButtonClick = false;
    @api headerAlignment;
    @api noDownloadLink = false;
    contentDocuments = [];
    myContentDocuments = [];
    isContentDocumentsEmpty = false;
    @track filesToShow = [];

    get contentDocumentsArray() {
        return this.recordId === undefined ? this.files : this.contentDocuments;
    }

    get defaultTitle() {
        return setDefaultValue(this.title, 'Vedlegg');
    }

    get isDelete() {
        return convertStringToBoolean(this.isDeleteOption);
    }

    get headerAlign() {
        return 'align-items: ' + setDefaultValue(this.headerAlignment + ';', 'center;');
    }

    renderedCallback() {
        this.hasFiles();
    }

    hasFiles() {
        this.isContentDocumentsEmpty = this.contentDocuments.length === 0 && this.files.length === 0 ? true : false;
    }

    @api checkIfEmpty() {
        return this.isContentDocumentsEmpty;
    }

    fileButtonLabel;
    onFileFocus(event) {
        this.fileButtonLabel = '';
        const index = event.currentTarget.dataset.index;
        this.fileButtonLabel = 'Slett vedlegg ' + this.filesToShow[index].Title;
    }

    markFilesAvailableForDeletion() {
        this.filesToShow = [...this.contentDocumentsArray]; // Copy value to be able to set new attribute
        this.filesToShowLength = this.filesToShow.length > 0;
        this.filesToShow.forEach((item) => {
            this.myContentDocuments.forEach((myItem) => {
                if (item.Id === myItem) {
                    item.isDeletable = true;
                }
            });
        });
    }

    // Call this when submit/save is run to delete selected files
    @api deleteMarkedFiles() {
        if (this.filesToDelete.length > 0) {
            deleteFilesOnRecord({ files: this.filesToDelete }).then(() => {
                refreshApex(this.wiredGetContentDocumentsResult);
            });
        }
    }

    filesToDelete = [];
    filesToShowLength = false;
    onFileDelete(event) {
        const index = event.currentTarget.dataset.index;
        if (this.filesToShow.length < index) {
            return;
        }
        this.filesToDelete.push(this.filesToShow[index].Id);
        this.filesToShow.splice(index, 1);
        this.filesToShowLength = this.filesToShow.length > 0;
        if (this.deleteFileOnButtonClick) {
            this.deleteMarkedFiles();
        }
    }

    wiredGetContentDocumentsResult;
    @wire(getContentDocuments, { recordId: '$recordId', isGetAll: '$isGetAll' })
    async wiredgetContentDocuments(result) {
        this.wiredGetContentDocumentsResult = result;
        if (result.data) {
            const url = await getBaseDownloadUrl();

            // Using a Set to ensure unique ContentDocumentIds
            const uniqueContentDocumentIds = new Set();
            this.contentDocuments = [];

            result.data.forEach((item) => {
                if (!uniqueContentDocumentIds.has(item.Id)) {
                    uniqueContentDocumentIds.add(item.Id);
                    this.contentDocuments.push({
                        ...item,
                        downloadLink: url + item.Id
                    });
                }
            });

            this.hasFiles();
            const contentDocumentIds = Array.from(uniqueContentDocumentIds);

            getOnlyMyContentDocuments({ contentDocumentIds: contentDocumentIds }).then((res) => {
                this.myContentDocuments = res;
                this.markFilesAvailableForDeletion();
            });
        }
    }

    @api refreshContentDocuments() {
        refreshApex(this.wiredGetContentDocumentsResult);
    }
}
