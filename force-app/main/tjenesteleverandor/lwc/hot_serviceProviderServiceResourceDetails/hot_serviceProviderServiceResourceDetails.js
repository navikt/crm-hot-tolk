import { LightningElement, wire } from 'lwc';
import getSRDetails from '@salesforce/apex/HOT_TjenesteleverandorListController.getSRDetails';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

const RESOURCE_FIELDS = [
    { field: 'Name', label: 'Navn' },
    { field: 'IsActive', label: 'Aktiv', boolean: true },
    { field: 'HOT_Skilled__c', label: 'Faglært', boolean: true },
    { field: 'HOT_ServiceTerritory__r', label: 'Ressursens tjenesteområde', lookup: true },
    { field: 'HOT_NotificationChannel__c', label: 'Varslingskanal' },
    { field: 'Description', label: 'Beskrivelse' },
    { field: 'HOT_MoreInformation__c', label: 'Mer informasjon' }
];

const CONTACT_FIELDS = [
    { field: 'HOT_Address__c', label: 'Adresse' },
    { field: 'HOT_Email__c', label: 'E-post' },
    { field: 'HOT_MobilePhone__c', label: 'Mobilnummer' },
    { field: 'HOT_MobileDevice__c', label: 'Mobil enhet' }
];

const TAG_DEFINITIONS = [
    { id: 'Tromso', label: 'Troms og Finnmark' },
    { id: 'Nordland', label: 'Nordland' },
    { id: 'More_og_Romsdal', label: 'Møre og Romsdal' },
    { id: 'Vest_Viken', label: 'Vest-Viken' },
    { id: 'Oslo', label: 'Oslo' },
    { id: 'Rogaland', label: 'Rogaland' },
    { id: 'Trondelag', label: 'Trøndelag' },
    { id: 'Vestland', label: 'Vestland' },
    { id: 'Innlandet', label: 'Innlandet' },
    { id: 'Ost_Viken', label: 'Øst-Viken' },
    { id: 'Vestfold_og_Telemark', label: 'Vestfold og Telemark' },
    { id: 'Agder', label: 'Agder' }
];

export default class Hot_serviceProviderServiceResourceDetails extends NavigationMixin(LightningElement) {
    routeRecordId;
    recordData;

    isLoading = true;
    hasError = false;

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        if (!pageReference) {
            return;
        }

        const isDetailsPage =
        pageReference.type === 'comm__namedPage' &&
        pageReference.attributes?.name === 'Tjenesteressursdetaljer__c';

        if (!isDetailsPage) {
            this.hasError = false;
            return;
        }

        const recordId = pageReference.state?.c__recordId;
        if (recordId !== this.routeRecordId || !recordId) {
            this.recordData = undefined;
            this.hasError = !recordId;
            this.isLoading = Boolean(recordId);
            this.routeRecordId = recordId;
        }
    }

    @wire(getSRDetails, { recordId: '$recordId' })
    wiredRecord({ data, error }) {
        if (data) {
            this.recordData = data;
            this.hasError = false;
            this.isLoading = false;
        } else if (error || data === null) {
            this.recordData = undefined;
            this.hasError = true;
            this.isLoading = false;
        }
    }

    get recordId() {
        return this.routeRecordId;
    }

    get hasRecordData() {
        return Boolean(this.recordData) && !this.hasError && !this.isLoading;
    }

    get resourceFields() {
        return this.formatFields(RESOURCE_FIELDS);
    }

    get contactFields() {
        return this.formatFields(CONTACT_FIELDS);
    }

    get preferredRegionTags() {
        // Apex can return toLabel labels or raw multipicklist API values.
        const values = (this.recordData?.HOT_PreferredRegions__c || '')
            .split(';')
            .map((value) => value.trim())
            .filter(Boolean);
        const tags = values.map(
            (value) => TAG_DEFINITIONS.find(({ id, label }) => id === value || label === value) || { id: value, label: value }
        );
        return [...new Map(tags.map((tag) => [tag.id, tag])).values()];
    }

    get hasPreferredRegionTags() {
        return this.preferredRegionTags.length > 0;
    }

    formatFields(definitions) {
        return definitions.map(({ field, label, boolean, lookup }) => {
            const rawValue = this.recordData?.[field];
            let value = lookup ? rawValue?.Name : rawValue;
            if (boolean && typeof rawValue === 'boolean') {
                value = rawValue ? 'Ja' : 'Nei';
            }
            return { label, value: value === undefined || value === null || value === '' ? '—' : value };
        });
    }

    handleBack() {
        if (window.history && window.history.length > 1) {
            window.history.back();
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Tjenesteressurser__c'
            }
        });
    }
}
