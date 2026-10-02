import { createElement } from 'lwc';
import HotTjenesteleverandorServiceappointmentWrapper from 'c/hot_tjenesteleverandorServiceappointmentWrapper';
import { CurrentPageReference } from 'lightning/navigation';

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-hot-tjenesteleverandor-serviceappointment-wrapper', () => {
    beforeEach(() => {
        sessionStorage.clear();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the shared filter button and forwards filters to the active list', async () => {
        const element = createElement('c-hot-tjenesteleverandor-serviceappointment-wrapper', {
            is: HotTjenesteleverandorServiceappointmentWrapper
        });
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { list: 'transferred' } });
        await flushPromises();

        const filterButton = element.shadowRoot.querySelector('c-list-filters-button');
        expect(filterButton).not.toBeNull();
        expect(filterButton.filters).toHaveLength(5);

        const filters = JSON.parse(JSON.stringify(filterButton.filters));
        const regionFilter = filters.find((filter) => filter.name === 'HOT_ServiceTerritoryDeveloperName__c');
        regionFilter.value.find((region) => region.name === 'Oslo').value = true;
        filterButton.dispatchEvent(
            new CustomEvent('getfilteredrecordslength', {
                detail: { filterArray: filters, setRecords: true }
            })
        );
        await flushPromises();

        expect(JSON.parse(sessionStorage.getItem('tjenesteleverandorTransferredFilters'))).toEqual(filters);
        expect(filterButton.filteredRecordsLength).toBe(0);
    });
});
