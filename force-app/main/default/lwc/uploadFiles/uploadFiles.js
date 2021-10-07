import { LightningElement, api } from 'lwc';
import uploadFile from '@salesforce/apex/HOT_RequestListContoller.uploadFile';

export default class uploadFiles extends LightningElement {
    @api recordId;

    isDrop = false;
    dropHandler(event) {
        event.preventDefault();
        this.isDrop = true;
        this.onFileUpload(event);
    }

    dragOverHandler(event) {
        event.preventDefault();
    }

    // Reset value of file input path so that same file can be uploaded again if deleting file and re-uploading
    resetFileValue() {
        this.template.querySelector('[data-id="file-input"]').value = null;
    }

    onFileButtonClick(event) {
        const index = event.currentTarget.dataset.index;
        if (this.fileData.length < index) {
            return;
        }
        this.fileData.splice(index, 1);
        this.boolSwitch();
        this.showOrHideCheckbox();
        this.setCheckboxContent();
    }

    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
    }

    focusCheckbox() {
        this.template.querySelector('c-checkbox').focusCheckbox();
    }

    setButtonStyleOnFocus() {
        let inputEle = this.template.querySelector('[data-id="file-input"]');
        if (this.template.activeElement === inputEle) {
            document.documentElement.style.setProperty('--outline', 'none');
            document.documentElement.style.setProperty('--boxShadow', '0 0 0 3px #00347d');
        } else {
            document.documentElement.style.setProperty('--outline', 'none');
            document.documentElement.style.setProperty('--boxShadow', 'none');
        }
    }

    checkboxContent;
    setCheckboxContent() {
        this.checkboxContent =
            this.fileData.length > 1
                ? 'Dokumentene som er lagt ved gir bakgrunnsinformasjon om mitt innmeldte behov for tolk. Informasjonen er nødvendig for at behovet skal bli forsvarlig dekket. Jeg er klar over at vedleggene vil bli delt med tolken(e) som blir tildelt oppdraget.'
                : 'Dokumentet som er lagt ved gir bakgrunnsinformasjon om mitt innmeldte behov for tolk. Informasjonen er nødvendig for at behovet skal bli forsvarlig dekket. Jeg er klar over at vedlegget vil bli delt med tolken(e) som blir tildelt oppdraget.';
    }

    showOrHideCheckbox() {
        if (this.fileData.length === 0) {
            this.template.querySelector('.checkboxClass').classList.add('hidden');
        } else {
            this.template.querySelector('.checkboxClass').classList.remove('hidden');
            this.focusCheckbox();
        }
    }

    checkboxValue = false;
    handleCheckboxValue(event) {
        this.checkboxValue = event.detail;
        this.template.querySelector('c-checkbox').validationHandler(''); // Clear validation when clicking checkbox. Only validate on Submit.
    }

    @api
    validateCheckbox() {
        if (!this.checkboxValue) {
            this.template
                .querySelector('c-checkbox')
                .validationHandler(
                    'For å legge til vedlegg må du gi samtykke til at formidler og tolk kan se vedleggene som lastes opp'
                );
        }
    }

    fileButtonLabel;
    onFileFocus(event) {
        this.fileButtonLabel = '';
        const index = event.currentTarget.dataset.index;
        this.fileButtonLabel = 'Slett vedlegg ' + this.fileData[index].filename;
    }

    // Make boolean value change and set it to true to show new files added
    boolSwitch() {
        this.filesChanged = false;
        this.filesChanged = true;
    }

    filesChanged = false; // If true -> shows new files added in list
    modalContent;
    fileData = [];
    async onFileUpload(event) {
        try {
            const result = this.isDrop
                ? await Promise.all([...event.dataTransfer.files].map((item) => this.readFile(item)))
                : await Promise.all([...event.target.files].map((item) => this.readFile(item)));
            result.forEach((item) => {
                // Only push new files
                if (this.fileData.findIndex((storedItem) => storedItem.base64 === item.base64) === -1) {
                    this.fileData.push(item);
                    this.boolSwitch();
                }
            });
            this.resetFileValue();
            this.setCheckboxContent();
            this.showOrHideCheckbox();
        } catch (err) {
            this.fileData = [];
            this.modalContent = 'Filen(e) kunne ikke lastes opp. Feilmelding: ' + err;
            this.showModal();
        }
        this.isDrop = false;
    }

    readFile(file) {
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = () => {
                resolve({
                    filename: file.name,
                    base64: reader.result.split(',')[1],
                    recordId: this.recordId
                });
            };
            reader.readAsDataURL(file);
        });
    }

    @api
    clearFileData() {
        this.fileData = [];
        this.resetFileValue();
        this.showOrHideCheckbox();
    }

    @api
    checkFileDataSize() {
        if (this.fileData.length > 0) {
            return true;
        }
        return false;
    }

    @api
    handleFileUpload() {
        if (this.fileData.length === 0) {
            return;
        }
        if (this.checkboxValue) {
            const filesToUpload = {};
            this.fileData.forEach((item) => {
                const { base64, filename } = item;
                filesToUpload[base64] = filename;
            });
            uploadFile({ files: filesToUpload, recordId: this.recordId });
            this.fileData = [];
        } else {
            this.template
                .querySelector('c-checkbox')
                .validationHandler(
                    'For å legge til vedlegg må du gi samtykke til at formidler og tolk kan se vedleggene som lastes opp'
                );
        }
    }
}
