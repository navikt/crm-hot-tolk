import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';

const FIELDS = {
    id: 'HOT_InterestedResource__c.Id',
    resourceId: 'HOT_InterestedResource__c.ServiceResource__c',
    resourceName: 'HOT_InterestedResource__c.ServiceResource__r.Name',
    isFreelance: 'HOT_InterestedResource__c.ServiceResource__r.HOT_IsFreelanceInterpreter__c',
    isEmployed: 'HOT_InterestedResource__c.ServiceResource__r.HOT_IsEmployedInterpreter__c',
    status: 'HOT_InterestedResource__c.Status__c',
    serviceTerritory: 'HOT_InterestedResource__c.ServiceTerritory__c',
    comments: 'HOT_InterestedResource__c.Comments__c'
};
const RELATED_LIST_FIELDS = Object.values(FIELDS);

export default class Hot_interestedResourceInternalList extends LightningElement {
    resources = [];
    isLoading = false;
    errorMessage;
    pageToken = null;
    _recordId;
    pages = new Map();

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value !== this._recordId) {
            this._recordId = value;
            this.pages.clear();
            this.resources = [];
            this.errorMessage = undefined;
            this.pageToken = null;
            this.isLoading = Boolean(value);
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'InterestedResources__r',
        fields: RELATED_LIST_FIELDS,
        pageSize: 1999,
        pageToken: '$pageToken'
    })
    wiredResources({ data, error }) {
        if (data) {
            const resources = data.records.map((record) => {
                const resourceId = getFieldValue(record, FIELDS.resourceId);
                const isFreelance = getFieldValue(record, FIELDS.isFreelance);
                const isEmployed = getFieldValue(record, FIELDS.isEmployed);
                const showName = resourceId && (isFreelance || isEmployed);
                return {
                    id: record.id,
                    resourceName: showName ? getFieldValue(record, FIELDS.resourceName) : '',
                    resourceUrl:
                        resourceId && !isFreelance && isEmployed
                            ? `/lightning/r/ServiceResource/${resourceId}/view`
                            : '',
                    status: getFieldDisplayValue(record, FIELDS.status) ?? getFieldValue(record, FIELDS.status),
                    serviceTerritory: getFieldValue(record, FIELDS.serviceTerritory),
                    comments: getFieldValue(record, FIELDS.comments)
                };
            });
            this.pages.set(data.currentPageToken, resources);
            this.resources = [...this.pages.values()].flat();
            this.errorMessage = undefined;
            this.isLoading = Boolean(data.nextPageToken);
            if (data.nextPageToken) {
                this.pageToken = data.nextPageToken;
            }
        } else if (error) {
            const messages = Array.isArray(error.body)
                ? error.body.map((item) => item.message).join(', ')
                : error.body?.message || error.message;
            this.errorMessage = messages || 'Kunne ikke hente interesserte ressurser.';
            this.pages.clear();
            this.resources = [];
            this.isLoading = false;
        }
    }

    get title() {
        return `Interesserte ressurser (${this.resources.length})`;
    }

    get hasResources() {
        return this.resources.length > 0;
    }
}
