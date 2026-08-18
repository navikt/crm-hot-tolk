import { LightningElement, api } from 'lwc';

export default class RecordFilesWithSharing extends LightningElement {
    @api recordId;
    @api isGetAll;
    @api isDeleteOption;
    @api title;
    @api deleteFileOnButtonClick;
}
