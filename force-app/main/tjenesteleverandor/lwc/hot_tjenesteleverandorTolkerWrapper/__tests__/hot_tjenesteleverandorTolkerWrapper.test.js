import { createElement } from '@lwc/engine-dom';
import Hot_tjenesteleverandorTolkerWrapper from 'c/hot_tjenesteleverandorTolkerWrapper';
import getServiceResources from '@salesforce/apex/HOT_TjenesteleverandorListController.getServiceResources';
import magnifyingGlass from '@salesforce/resourceUrl/MagnifyingGlass';
import * as sharedFilters from 'c/hot_tjenesteleverandorFilters';

jest.mock('c/hot_sharedFonts', () => ({ __esModule: true, default: [] }), { virtual: true });

jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorListController.getServiceResources',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

describe('c-hot-tjenesteleverandor-tolker-wrapper', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.restoreAllMocks();
    });

    it('renders a labelled, empty search field and preserves filtering and clearing', async () => {
        const element = createElement('c-hot-tjenesteleverandor-tolker-wrapper', {
            is: Hot_tjenesteleverandorTolkerWrapper
        });
        document.body.appendChild(element);
        getServiceResources.emit([
            { Id: '1', Name: 'Anna', IsActive: true },
            { Id: '2', Name: 'Bjørn', IsActive: true }
        ]);
        await Promise.resolve();

        const input = element.shadowRoot.querySelector('.search-field input.search-input');
        expect(input.type).toBe('search');
        expect(input.getAttribute('aria-label')).toBe('Søk på navn');
        expect(input.hasAttribute('placeholder')).toBe(false);
        expect(input.value).toBe('');
        const icon = element.shadowRoot.querySelector('.search-field svg.search-icon');
        expect(icon.getAttribute('width')).toBe('16');
        expect(icon.getAttribute('height')).toBe('16');
        expect(icon.getAttribute('viewBox')).toBe('3.25 3.25 18.52 18.52');
        expect(icon.getAttribute('aria-hidden')).toBe('true');
        expect(icon.getAttribute('focusable')).toBe('false');
        const image = icon.querySelector('image');
        expect(image.getAttribute('href')).toBe(magnifyingGlass);
        expect(image.getAttribute('width')).toBe('24');
        expect(image.getAttribute('height')).toBe('24');
        expect(icon.querySelector('use, circle, path')).toBeNull();

        input.value = 'ANNA';
        input.dispatchEvent(new Event('input'));
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('c-hot_freelance-common-table').records.map((r) => r.Name)).toEqual([
            'Anna'
        ]);

        input.value = 'ingen treff';
        input.dispatchEvent(new Event('input'));
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('c-hot_freelance-common-table')).toBeNull();
        expect(element.shadowRoot.textContent).toContain('Ingen resultater for søket og valgte filtre.');
        expect(element.shadowRoot.querySelector('input')).toBe(input);

        input.value = '';
        input.dispatchEvent(new Event('input'));
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('c-hot_freelance-common-table').records).toHaveLength(2);
    });

    describe('region and activity filters', () => {
        const regionField = 'HOT_ServiceTerritoryDeveloperName__c';
        const defaultRegion = () => sharedFilters.createDefaultFilters().find((group) => group.name === regionField);
        const uncheckedRegion = () => ({
            ...defaultRegion(),
            value: defaultRegion().value.map((option) => ({ ...option, value: false, checked: false }))
        });
        const resources = [
            {
                Id: '1',
                Name: 'Anna',
                IsActive: true,
                HOT_ServiceTerritory__r: { Name: 'Oslo', HOT_DeveloperName__c: 'Oslo' }
            },
            {
                Id: '2',
                Name: 'Anne',
                IsActive: false,
                HOT_ServiceTerritory__r: { Name: 'Oslo', HOT_DeveloperName__c: 'Oslo' }
            },
            {
                Id: '3',
                Name: 'Bjørn',
                IsActive: true,
                HOT_ServiceTerritory__r: { Name: 'Agder', HOT_DeveloperName__c: 'Agder' }
            },
            {
                Id: '4',
                Name: 'Bente',
                IsActive: false,
                HOT_ServiceTerritory__r: { Name: 'Agder', HOT_DeveloperName__c: 'Agder' }
            },
            { Id: '5', Name: 'Cecilie', IsActive: false }
        ];
        let element;
        const button = () => element.shadowRoot.querySelector('c-list-filters-button');
        const ids = () =>
            element.shadowRoot.querySelector('c-hot_freelance-common-table')?.records.map((record) => record.Id) ?? [];
        const selections = (regions = [], statuses = []) =>
            button().filters.map((group) => ({
                ...group,
                value: group.value.map((option) => {
                    const checked = (group.name === regionField ? regions : statuses).includes(option.name);
                    return { ...option, value: checked, checked };
                })
            }));
        const send = async (type, filterArray) => {
            button().dispatchEvent(
                new CustomEvent(type, { detail: { filterArray, setRecords: type === 'applyfilter' } })
            );
            await Promise.resolve();
        };
        const search = async (value) => {
            const input = element.shadowRoot.querySelector('input');
            input.value = value;
            input.dispatchEvent(new Event('input'));
            await Promise.resolve();
        };

        beforeEach(async () => {
            element = createElement('c-hot-tjenesteleverandor-tolker-wrapper', {
                is: Hot_tjenesteleverandorTolkerWrapper
            });
            document.body.appendChild(element);
            getServiceResources.emit(resources);
            await Promise.resolve();
        });

        it('uses the exact shared region choices even when resources contain only a subset', () => {
            expect(button().filters).toEqual([
                uncheckedRegion(),
                {
                    name: 'IsActiveLabel',
                    label: 'Status',
                    isCheckboxgroup: true,
                    value: ['Aktiv', 'Inaktiv'].map((name) => ({
                        name,
                        label: name,
                        value: false,
                        checked: false
                    }))
                }
            ]);
            expect(ids()).toEqual(['1', '2', '3', '4', '5']);
        });

        it('keeps the complete shared region definitions with empty wire data', async () => {
            // The empty-list view hides the controls, so inspect the filters used by the wrapper.
            const filterSpy = jest.spyOn(sharedFilters, 'filterRecords');
            getServiceResources.emit([]);
            await Promise.resolve();

            expect(filterSpy).toHaveBeenLastCalledWith(
                [],
                [uncheckedRegion(), expect.objectContaining({ label: 'Status' })]
            );
            expect(element.shadowRoot.textContent).toContain('Ingen tolker funnet.');

            getServiceResources.emit(resources);
            await Promise.resolve();
            expect(button().filters[0]).toEqual(uncheckedRegion());
        });

        it.each([
            ['More_og_Romsdal', 'Møre og Romsdal'],
            ['Trondelag', 'Trøndelag'],
            ['Tromso', 'Troms og Finnmark'],
            ['Ost_Viken', 'Øst-Viken']
        ])('matches developer name %s rather than display label %s', async (developerName, label) => {
            getServiceResources.emit([
                ...resources,
                {
                    Id: '6',
                    Name: 'Dina',
                    IsActive: true,
                    HOT_ServiceTerritory__r: { Name: label, HOT_DeveloperName__c: developerName }
                },
                {
                    Id: '7',
                    Name: 'Eli',
                    IsActive: true,
                    HOT_ServiceTerritory__r: { Name: label, HOT_DeveloperName__c: 'Oslo' }
                }
            ]);
            await Promise.resolve();
            expect(button().filters[0].value.find((option) => option.name === developerName).label).toBe(label);

            const draft = selections([developerName], ['Aktiv']);
            await send('getfilteredrecordslength', draft);
            expect(button().filteredRecordsLength).toBe(1);
            expect(ids()).toHaveLength(7);
            await send('applyfilter', draft);
            expect(ids()).toEqual(['6']);
            expect(element.shadowRoot.querySelector('c-hot_freelance-common-table').records[0].Region).toBe(label);
        });

        it.each([
            [['Oslo'], [], ['1', '2']],
            [[], ['Aktiv'], ['1', '3']],
            [[], ['Inaktiv'], ['2', '4', '5']],
            [['Oslo', 'Agder'], ['Inaktiv'], ['2', '4']],
            [['Agder'], ['Aktiv', 'Inaktiv'], ['3', '4']],
            [[], [], ['1', '2', '3', '4', '5']]
        ])('applies region %j and status %j', async (regions, statuses, expected) => {
            await send('applyfilter', selections(regions, statuses));
            expect(ids()).toEqual(expected);
        });

        it('counts drafts synchronously without applying them, including the current name search', async () => {
            await search('AN');
            const draft = selections(['Oslo'], ['Inaktiv']);
            button().dispatchEvent(
                new CustomEvent('getfilteredrecordslength', { detail: { filterArray: draft, setRecords: false } })
            );
            expect(button().filteredRecordsLength).toBe(1);
            expect(ids()).toEqual(['1', '2']);
            expect(button().filters[1].value.every((option) => !option.checked)).toBe(true);

            await search('Anna');
            expect(ids()).toEqual(['1']);
            expect(button().filteredRecordsLength).toBe(0);
            await search('');
            expect(ids()).toHaveLength(5);

            await send('applyfilter', draft);
            expect(ids()).toEqual(['2']);
            // Later mutations of the panel draft must not mutate applied state.
            draft[1].value.forEach((option) => {
                option.value = false;
                option.checked = false;
            });
            await search('AN');
            expect(ids()).toEqual(['2']);
        });

        it('combines applied filters and name search and allows clearing independently', async () => {
            await send('applyfilter', selections(['Agder'], ['Aktiv']));
            await search('ANNA');
            expect(ids()).toEqual([]);
            expect(element.shadowRoot.textContent).toContain('Ingen resultater for søket og valgte filtre.');
            expect(button()).not.toBeNull();
            expect(element.shadowRoot.querySelector('input')).not.toBeNull();

            await send('applyfilter', selections());
            expect(ids()).toEqual(['1']);
            await search('');
            expect(ids()).toHaveLength(5);
            await send('applyfilter', selections(['Oslo'], ['Inaktiv']));
            await search('ingen treff');
            await search('');
            expect(ids()).toEqual(['2']);
        });

        it('keeps controls available for a filter-only empty result and clears back to all records', async () => {
            const draft = selections(['Vestland'], ['Aktiv']);
            await send('getfilteredrecordslength', draft);
            expect(button().filteredRecordsLength).toBe(0);
            expect(ids()).toHaveLength(5);
            await send('applyfilter', draft);
            expect(ids()).toEqual([]);
            expect(element.shadowRoot.textContent).toContain('Ingen resultater for søket og valgte filtre.');
            expect(element.shadowRoot.querySelector('input')).not.toBeNull();
            await send('applyfilter', selections());
            expect(ids()).toHaveLength(5);
        });

        it('preserves applied selections and name search across wire refreshes', async () => {
            await send('applyfilter', selections(['Oslo'], ['Inaktiv']));
            await search('AN');
            getServiceResources.emit([
                ...resources,
                {
                    Id: '6',
                    Name: 'Anita',
                    IsActive: false,
                    HOT_ServiceTerritory__r: { Name: 'Oslo', HOT_DeveloperName__c: 'Oslo' }
                },
                {
                    Id: '7',
                    Name: 'Arne',
                    IsActive: true,
                    HOT_ServiceTerritory__r: { Name: 'Vestland', HOT_DeveloperName__c: 'Vestland' }
                }
            ]);
            await Promise.resolve();
            expect(ids()).toEqual(['2', '6']);
            expect(button().filters[0].value.find((option) => option.name === 'Oslo').checked).toBe(true);
            expect(button().filters[0].value.find((option) => option.name === 'Vestland').checked).toBe(false);
            expect(button().filters[1].value.find((option) => option.name === 'Inaktiv').checked).toBe(true);

            getServiceResources.emit(resources.filter((resource) => resource.HOT_ServiceTerritory__r?.Name !== 'Oslo'));
            await Promise.resolve();
            expect(ids()).toEqual([]);
            expect(button().filters[0].value.find((option) => option.name === 'Oslo').checked).toBe(true);
        });
    });
});
