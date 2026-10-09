import { LightningElement, wire } from 'lwc';
import getCurrentUserServiceResource from '@salesforce/apex/HOT_TLUserInformationController.getCurrentUserServiceResource';
import updatePreferredRegions from '@salesforce/apex/HOT_TLUserInformationController.updatePreferredRegions';

export default class Hot_tjenesteleverandorUserInfo extends LightningElement {
    isLoading = true;
    loadError;
    saveError;
    showSaveSuccess = false;
    serviceResource;
    buttonLoading = false;
    savedRegionValues = '';

    regionOptions = [
        { label: 'Agder', value: 'Agder', selected: false },
        { label: 'Innlandet', value: 'Innlandet', selected: false },
        { label: 'Møre og Romsdal', value: 'More_og_Romsdal', selected: false },
        { label: 'Nordland', value: 'Nordland', selected: false },
        { label: 'Oslo', value: 'Oslo', selected: false },
        { label: 'Rogaland', value: 'Rogaland', selected: false },
        { label: 'Trøndelag', value: 'Trondelag', selected: false },
        { label: 'Troms og Finnmark', value: 'Tromso', selected: false },
        { label: 'Vest-Viken', value: 'Vest_Viken', selected: false },
        { label: 'Vestland', value: 'Vestland', selected: false },
        { label: 'Vestfold og Telemark', value: 'Vestfold_og_Telemark', selected: false },
        { label: 'Øst-Viken', value: 'Ost_Viken', selected: false }
    ];

    @wire(getCurrentUserServiceResource)
    wiredServiceResource({ data, error }) {
        if (data === undefined && error === undefined) {
            return;
        }

        if (data) {
            this.serviceResource = data;
            const selectedValues = new Set((data.HOT_PreferredRegions__c || '').split(';').filter(Boolean));
            this.regionOptions = this.regionOptions.map((region) => ({
                ...region,
                selected: selectedValues.has(region.value)
            }));
            this.savedRegionValues = this.selectedRegionValues;
        } else if (error) {
            this.loadError = error.body?.message || 'Kunne ikke hente regioner.';
        }
        this.isLoading = false;
    }

    get hasServiceResource() {
        return Boolean(this.serviceResource);
    }

    get leftRegionOptions() {
        return this.regionOptions.slice(0, Math.ceil(this.regionOptions.length / 2));
    }

    get rightRegionOptions() {
        return this.regionOptions.slice(Math.ceil(this.regionOptions.length / 2));
    }

    get selectedRegionValues() {
        return this.regionOptions
            .filter((region) => region.selected)
            .map((region) => region.value)
            .join(';');
    }

    get hasUnsavedChanges() {
        return this.hasServiceResource && this.selectedRegionValues !== this.savedRegionValues;
    }

    handleRegionSelectionChange(event) {
        const selectedValue = event.target.dataset.value;
        const isChecked = event.detail;
        this.regionOptions = this.regionOptions.map((region) =>
            region.value === selectedValue ? { ...region, selected: isChecked } : region
        );
        this.saveError = undefined;
        this.showSaveSuccess = false;
    }

    handleCancel() {
        if (this.buttonLoading) {
            return;
        }

        const savedValues = new Set(this.savedRegionValues.split(';').filter(Boolean));
        this.regionOptions = this.regionOptions.map((region) => ({
            ...region,
            selected: savedValues.has(region.value)
        }));
        this.template.querySelectorAll('c-checkbox').forEach((checkbox) => {
            checkbox.setCheckboxValue(savedValues.has(checkbox.dataset.value));
        });
        this.saveError = undefined;
        this.showSaveSuccess = false;
    }

    async handleSave() {
        if (!this.hasUnsavedChanges || this.buttonLoading) {
            return;
        }

        this.buttonLoading = true;
        this.saveError = undefined;
        this.showSaveSuccess = false;
        const submittedRegionValues = this.selectedRegionValues;
        try {
            await updatePreferredRegions({
                selectedRegions: this.regionOptions.filter((region) => region.selected).map((region) => region.value)
            });
            this.savedRegionValues = submittedRegionValues;
            this.showSaveSuccess = this.selectedRegionValues === submittedRegionValues;
        } catch (error) {
            this.saveError = error.body?.message || 'Kunne ikke lagre regionvalgene.';
        } finally {
            this.buttonLoading = false;
        }
    }
}
