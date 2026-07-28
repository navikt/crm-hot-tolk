import { createElement } from 'lwc';
import { registerTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import HotTjenesteleverandorServiceAppointmentDetail from 'c/hot_tjenesteleverandorServiceAppointmentDetail';
import { CurrentPageReference, Navigate } from 'lightning/navigation';

const RECORD_ID = '08p000000000001AAA';
const currentPageReferenceAdapter = registerTestWireAdapter(CurrentPageReference);
const flushPromises = () => Promise.resolve();

function createComponent() {
    const element = createElement('c-hot-tjenesteleverandor-service-appointment-detail', {
        is: HotTjenesteleverandorServiceAppointmentDetail
    });
    element.recordId = RECORD_ID;
    document.body.appendChild(element);
    return element;
}

function dispatchLoad(form, cancellationFields = {}) {
    form.dispatchEvent(
        new CustomEvent('load', {
            detail: {
                records: {
                    [RECORD_ID]: {
                        fields: {
                            HOT_CancelComment__c: { value: null },
                            HOT_CanceledByInterpreter__c: { value: false },
                            HOT_CanceledDate__c: { value: null },
                            HOT_LateCancellation__c: { value: false },
                            ...cancellationFields
                        }
                    }
                }
            }
        })
    );
}

function getCancellationSection(element) {
    const cancellationHeading = [...element.shadowRoot.querySelectorAll('h2')].find(
        (heading) => heading.textContent === 'Avlysning'
    );
    return cancellationHeading.parentElement;
}

describe('c-hot-tjenesteleverandor-service-appointment-detail', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        Navigate.mockClear();
        jest.restoreAllMocks();
        delete window.history.length;
    });

    it('shows a loading state until Lightning Data Service loads the record', () => {
        const element = createComponent();

        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
        expect(element.shadowRoot.querySelector('lightning-record-view-form').classList).toContain(
            'record-form_hidden'
        );
        expect(element.shadowRoot.querySelector('.error-message')).toBeNull();
    });

    it('reads the appointment ID from the separate Experience page state', async () => {
        const element = createElement('c-hot-tjenesteleverandor-service-appointment-detail', {
            is: HotTjenesteleverandorServiceAppointmentDetail
        });
        document.body.appendChild(element);

        currentPageReferenceAdapter.emit({
            state: {
                c__recordId: RECORD_ID
            }
        });
        await flushPromises();

        expect(element.shadowRoot.querySelector('lightning-record-view-form').recordId).toBe(RECORD_ID);
    });

    it('renders the operational fields read-only after a successful load', async () => {
        const element = createComponent();
        const form = element.shadowRoot.querySelector('lightning-record-view-form');

        dispatchLoad(form);
        await flushPromises();

        const fieldNames = [...element.shadowRoot.querySelectorAll('lightning-output-field')].map(
            (field) => field.fieldName
        );
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        expect(form.classList).not.toContain('record-form_hidden');
        expect(fieldNames).toEqual(
            expect.arrayContaining([
                'AppointmentNumber',
                'HOT_FreelanceSubject__c',
                'Status',
                'HOT_TjenesteleverandorStatus__c',
                'EarliestStartTime',
                'DueDate',
                'HOT_AddressFormated__c',
                'HOT_TjenesteleverandorDeadline__c'
            ])
        );
        expect(fieldNames).not.toEqual(
            expect.arrayContaining(['ParentRecordId', 'WorkTypeId', 'AccountId', 'ContactId', 'OwnerId'])
        );
        expect(element.shadowRoot.querySelector('lightning-input-field')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-record-edit-form')).toBeNull();
        expect(element.shadowRoot.querySelectorAll('lightning-button')).toHaveLength(1);
        expect(getCancellationSection(element).classList).toContain('detail-section_hidden');
    });

    it('shows cancellation details only when cancellation data is populated', async () => {
        const element = createComponent();
        const form = element.shadowRoot.querySelector('lightning-record-view-form');

        dispatchLoad(form, { HOT_CancelComment__c: { value: 'Avlyst av bestiller' } });
        await flushPromises();

        expect(getCancellationSection(element).classList).not.toContain('detail-section_hidden');
    });

    it('shows the same generic message for inaccessible or missing records', async () => {
        const element = createComponent();
        const form = element.shadowRoot.querySelector('lightning-record-view-form');

        form.dispatchEvent(new CustomEvent('error'));
        await flushPromises();

        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        expect(form.classList).toContain('record-form_hidden');
        expect(element.shadowRoot.querySelector('.error-message').textContent).toContain(
            'Du har ikke tilgang til oppdraget, eller oppdraget finnes ikke.'
        );
    });

    it('returns through browser history when a previous page exists', () => {
        Object.defineProperty(window.history, 'length', { configurable: true, value: 2 });
        const backSpy = jest.spyOn(window.history, 'back').mockImplementation(() => {});
        const element = createComponent();

        element.shadowRoot.querySelector('lightning-button').click();

        expect(backSpy).toHaveBeenCalledTimes(1);
        expect(Navigate).not.toHaveBeenCalled();
    });

    it('navigates to the site home page when browser history is unavailable', () => {
        Object.defineProperty(window.history, 'length', { configurable: true, value: 1 });
        const element = createComponent();

        element.shadowRoot.querySelector('lightning-button').click();

        expect(Navigate).toHaveBeenCalledWith(
            {
                type: 'comm__namedPage',
                attributes: { name: 'home' }
            },
            undefined
        );
    });
});
