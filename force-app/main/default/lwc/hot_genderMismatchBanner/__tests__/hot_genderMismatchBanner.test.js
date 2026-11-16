import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import HotGenderMismatchBanner from 'c/hot_genderMismatchBanner';

const RECORD_ID = '08p000000000001AAA';
const RESOURCE_ID = '0Hn000000000001AAA';
const flushPromises = () => Promise.resolve();

function appointment(preferredGender, resourceGender, resourceId = RESOURCE_ID) {
    return {
        apiName: 'ServiceAppointment',
        id: RECORD_ID,
        fields: {
            HOT_Gender__c: { value: preferredGender },
            HOT_ServiceResource__c: { value: resourceId },
            HOT_ServiceResource__r: {
                value: resourceId
                    ? {
                          apiName: 'ServiceResource',
                          id: resourceId,
                          fields: { HOT_Gender__c: { value: resourceGender } }
                      }
                    : null
            }
        }
    };
}

function mountBanner() {
    const element = createElement('c-hot_gender-mismatch-banner', { is: HotGenderMismatchBanner });
    element.recordId = RECORD_ID;
    document.body.appendChild(element);
    return element;
}

afterEach(() => {
    document.body.replaceChildren();
    window.localStorage.clear();
    jest.restoreAllMocks();
});

it.each([
    ['Kvinne', 'Mann'],
    ['Mann', 'Kvinne'],
    ['Kvinne', 'Ukjent']
])('shows a mismatch for preference %s and resource %s', async (preferred, actual) => {
    const element = mountBanner();
    getRecord.emit(appointment(preferred, actual));
    await flushPromises();

    const banner = element.shadowRoot.querySelector('[role="status"]');
    expect(banner).not.toBeNull();
    expect(banner.textContent).toContain(`Ønsket kjønn: ${preferred}. Tolkens kjønn: ${actual}.`);
});

it.each([
    ['Kvinne', 'Kvinne', RESOURCE_ID],
    ['Ukjent', 'Ukjent', RESOURCE_ID],
    [null, 'Mann', RESOURCE_ID],
    ['Kvinne', null, null]
])('hides the banner without a mismatch or assignment (%s, %s, %s)', async (preferred, actual, resourceId) => {
    const element = mountBanner();
    getRecord.emit(appointment(preferred, actual, resourceId));
    await flushPromises();

    expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
});

it('remembers dismissal across remounts but shows changed mismatches', async () => {
    let element = mountBanner();
    getRecord.emit(appointment('Kvinne', 'Mann'));
    await flushPromises();
    element.shadowRoot.querySelector('button').click();
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();

    element.remove();
    element = mountBanner();
    getRecord.emit(appointment('Kvinne', 'Mann'));
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();

    getRecord.emit(appointment('Kvinne', 'Mann', '0Hn000000000002AAA'));
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();

    element.shadowRoot.querySelector('button').click();
    getRecord.emit(appointment('Mann', 'Ukjent', '0Hn000000000002AAA'));
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();
});

it('updates the banner when the mismatch is resolved', async () => {
    const element = mountBanner();
    getRecord.emit(appointment('Kvinne', 'Mann'));
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();

    getRecord.emit(appointment('Kvinne', 'Kvinne'));
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
});

it('reports record loading failures instead of silently hiding the check', async () => {
    const logError = jest.spyOn(console, 'error').mockImplementation(() => {});
    const element = mountBanner();
    getRecord.error();
    await flushPromises();

    expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
    expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('Kunne ikke kontrollere');
    expect(logError).toHaveBeenCalled();
});

it('still displays the warning when browser storage is unavailable', async () => {
    const logError = jest.spyOn(console, 'error').mockImplementation(() => {});
    jest.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new Error('Storage unavailable');
    });
    jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new Error('Storage unavailable');
    });
    const element = mountBanner();
    getRecord.emit(appointment('Kvinne', 'Mann'));
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();

    element.shadowRoot.querySelector('button').click();
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="status"]')).toBeNull();
    expect(logError).toHaveBeenCalledTimes(2);
});
