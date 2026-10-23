import { LightningElement, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getAllServiceResources from '@salesforce/apex/HOT_TLServiceResourceController.getAllServiceResources';
import getResourceDetails from '@salesforce/apex/HOT_TLServiceResourceController.getResourceDetails';

export default class Hot_flowWantedResourceSearch extends LightningElement {
    @api label;
    @api placeholder = 'Søk';
    @api clearButton = false;
    @api value = '';
    @api recordId;

    searchText = '';
    serviceResources = [];
    resourcesError;
    selectedResource;
    isLoadingDetails = false;
    detailsError;

    @wire(getAllServiceResources)
    wiredServiceResources({ data, error }) {
        if (data) {
            this.serviceResources = data;
            this.resourcesError = undefined;
        } else if (error) {
            this.serviceResources = [];
            this.resourcesError = error;
        }
    }

    handleChange(event) {
        this.searchText = event.target.value;
        this.value = '';
        this.selectedResource = undefined;
        this.detailsError = undefined;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    handleClear() {
        this.searchText = '';
        this.value = '';
        this.selectedResource = undefined;
        this.detailsError = undefined;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
        this.template.querySelector('input')?.focus();
    }

    handleKeyDown(event) {
        if (event.key === 'Escape' && this.searchText) {
            event.preventDefault();
            this.handleClear();
        }
    }

    async handleResourceSelect(event) {
        const resourceId = event.currentTarget.dataset.resourceId;
        const resource = this.serviceResources.find((item) => item.Id === resourceId);
        if (!resource || !this.recordId) {
            return;
        }

        this.searchText = resource.Name;
        this.value = resource.Id;
        this.selectedResource = undefined;
        this.isLoadingDetails = true;
        this.detailsError = undefined;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));

        try {
            this.selectedResource = await getResourceDetails({
                resourceId: resource.Id,
                serviceAppointmentId: this.recordId
            });
        } catch (error) {
            this.detailsError = error;
        } finally {
            this.isLoadingDetails = false;
        }
    }

    get matchingResources() {
        const query = this.searchText.trim();
        if (query.length < 2 || this.value) {
            return [];
        }

        const normalizedQuery = query.toLocaleLowerCase('nb-NO');
        return this.serviceResources
            .filter((resource) => resource.Name?.toLocaleLowerCase('nb-NO').includes(normalizedQuery))
            .sort((left, right) => left.Name.localeCompare(right.Name, 'nb-NO', { sensitivity: 'base' }))
            .slice(0, 5);
    }

    get showResults() {
        return this.searchText.trim().length >= 2 && !this.value && this.matchingResources.length > 0;
    }

    get hasPreferredRegions() {
        return this.selectedResource?.preferredRegions?.length > 0;
    }

    get hasRegionMismatch() {
        return Boolean(this.selectedResource?.serviceTerritoryName && !this.selectedResource.regionMatches);
    }

    get regionMatchLabel() {
        if (!this.selectedResource?.serviceTerritoryName) {
            return 'Oppdrag uten region';
        }
        return this.selectedResource.regionMatches ? 'Region matcher' : 'Region matcher ikke';
    }

    get regionMatchColor() {
        if (!this.selectedResource?.serviceTerritoryName) {
            return 'warning';
        }
        return this.selectedResource.regionMatches ? 'success' : 'danger';
    }

    get overlapLabel() {
        return this.selectedResource?.hasOverlap ? 'Overlappende oppdrag' : 'Tilgjengelig';
    }

    get overlapColor() {
        return this.selectedResource?.hasOverlap ? 'danger' : 'success';
    }

    get showClearButton() {
        return this.clearButton !== false && Boolean(this.searchText);
    }
}
