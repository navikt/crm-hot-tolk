import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getServiceResources from '@salesforce/apex/HOT_TjenesteleverandorListController.getServiceResources';
import searchIcon from '@salesforce/resourceUrl/MagnifyingGlass';
import { createDefaultFilters, filterRecords } from 'c/hot_tjenesteleverandorFilters';

export default class Hot_serviceProviderServiceResourceWrapper extends NavigationMixin(LightningElement) {
    allInterpretersList = [];
    interpretersList = [];
    searchIcon = searchIcon;
    dataLoader = true;
    filters = [];
    previewFilters;
    searchText = '';

    error = null;

    @wire(getServiceResources)
    wiredServiceResources({ error, data }) {
        if (data) {
            this.allInterpretersList = data.map((item) => ({
                ...item,
                Region: item.HOT_ServiceTerritory__r?.Name ?? 'Ikke tilgjengelig',
                HOT_ServiceTerritoryDeveloperName__c: item.HOT_ServiceTerritory__r?.HOT_DeveloperName__c,
                IsActiveLabel: item.IsActive ? 'Aktiv' : 'Inaktiv',
                statusBadgeClass: item.IsActive ? 'resource-badge badge-blue' : 'resource-badge badge-gray'
            }));
            this.error = null;
            this.updateFilters();
            this.interpretersList = this.getFilteredRecords(this.filters);
            this.dataLoader = false;
        } else if (error) {
            console.error('Error fetching service resources:', error);
            this.error = error;
            this.dataLoader = false;
            this.interpretersList = [];
            this.allInterpretersList = [];
        }
    }

    goToRecordDetails(event) {
        console.log("Pressed: ")
        const recordId = this.tolkerList.find((tolk) => tolk.Id === event.detail.Id)?.Id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Tjenesteressursdetaljer__c'
            },
            state: {
                c__recordId: recordId
            }
        });
    }

    handleSearch(event) {
        this.searchText = event.currentTarget.value.toLowerCase();
        this.interpretersList = this.getFilteredRecords(this.filters);
        this.updatePreviewCount();
    }

    applyFilter(event) {
        this.filters = JSON.parse(JSON.stringify(event.detail.filterArray));
        this.previewFilters = undefined;
        this.interpretersList = this.getFilteredRecords(this.filters);
    }

    sendFilteredRecordsLength(event) {
        // The panel owns its draft; never use it to update the table before Apply.
        this.previewFilters = JSON.parse(JSON.stringify(event.detail.filterArray));
        this.updatePreviewCount();
    }

    updatePreviewCount() {
        const count = this.getFilteredRecords(this.previewFilters ?? this.filters).length;
        this.template.querySelector('c-list-filters-button')?.setFilteredRecordsLength(count);
    }

    getFilteredRecords(filters) {
        return filterRecords(this.allInterpretersList, filters).filter((tolk) =>
            tolk.Name.toLowerCase().includes(this.searchText)
        );
    }

    updateFilters() {
        const definitions = [
            createDefaultFilters().find((filter) => filter.name === 'HOT_ServiceTerritoryDeveloperName__c'),
            {
                name: 'IsActiveLabel',
                label: 'Status',
                isCheckboxgroup: true,
                value: ['Aktiv', 'Inaktiv'].map((name) => ({ name, label: name }))
            }
        ];
        this.filters = definitions.map((definition) => {
            const previous = this.filters.find((filter) => filter.name === definition.name);
            return {
                ...definition,
                value: definition.value.map((option) => {
                    const checked = Boolean(previous?.value.find((value) => value.name === option.name)?.value);
                    return { ...option, value: checked, checked };
                })
            };
        });
        this.previewFilters = undefined;
    }

    get hasNoResult() {
        return !this.error && !this.dataLoader && this.allInterpretersList.length === 0;
    }

    get hasNoSearchResult() {
        return !this.error && !this.dataLoader && this.interpretersList.length === 0;
    }

    get hasResult() {
        return this.allInterpretersList.length > 0 && !this.dataLoader;
    }

    get hasError() {
        return !this.dataLoader && Boolean(this.error);
    }

    get errorMessage() {
        return this.error?.body?.message ?? 'Kunne ikke hente tolker.';
    }
}
