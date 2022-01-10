import { LightningElement, track, wire } from 'lwc';
import getMyWorkOrdersNew from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersNew';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { columns, mobileColumns, workOrderColumns, iconByValue } from './columns';
import { defaultFilters } from './filters';
export default class MineBestillingerWrapper extends NavigationMixin(LightningElement) {
    @track filters = [];
    connectedCallback() {
        this.filters = defaultFilters();
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }
    isList = true;
    isRequestDetails = false;
    isWorkOrderDetails = false;
    @track urlStateParameters;
    @track columns;
    @track workOrderColumns = workOrderColumns;
    @track iconByValue = iconByValue;

    @track records = [];
    @track allRecords = [];
    wiredMyWorkOrdersNewResult;
    @wire(getMyWorkOrdersNew)
    wiredMyWorkOrdersNew(result) {
        this.wiredMyWorkOrdersNewResult = result;
        if (result.data) {
            this.records = [...result.data];
            this.allRecords = [...result.data];
            this.refresh();
        }
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && this.isNavigatingAway === false) {
            this.urlStateParameters = { ...currentPageReference.state };
            this.refresh();
        }
    }

    @track request = { MeetingStreet__c: '', Subject__c: '' };
    @track workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    @track workOrders = [];
    interpreter = 'Tolk';
    getRecords() {
        let recordId = this.urlStateParameters.id;
        for (let record of this.records) {
            if (recordId === record.Id) {
                //console.log('WorkOrder: ', JSON.stringify(this.workOrder));
                this.workOrder = record;
                this.interpreter = this.workOrder?.HOT_Interpreters__c?.length > 1 ? 'Tolker' : 'Tolk';
                this.workOrderStartDate = this.formatDate(this.workOrder.StartDate, true);
                this.workOrderEndDate = this.formatDate(this.workOrder.EndDate, true);
                this.request = record.HOT_Request__r;
                //console.log('Request: ', JSON.stringify(this.request));
                this.requestSeriesStartDate = this.formatDate(this.request.SeriesStartDate__c, false);
                this.requestSeriesEndDate = this.formatDate(this.request.SeriesEndDate__c, false);
            }
        }
        if (this.request.Id !== undefined) {
            this.getWorkOrders();
        }
    }

    workOrderStartDate = '';
    workOrderEndDate = '';
    requestSeriesStartDate = '';
    requestSeriesEndDate = '';
    formatDate(dateInput, isWorkOrder) {
        let value = new Date(dateInput);
        value = value.toLocaleString();
        if (isWorkOrder) {
            return value.substring(0, value.length - 3);
        }
        return value.substring(0, value.length - 10);
    }

    getWorkOrders() {
        let workOrders = [];
        for (let record of this.records) {
            if (record.HOT_Request__c === this.request.Id) {
                workOrders.push(record);
            }
        }
        this.workOrders = workOrders;
    }

    isSeries = false;
    goToRecordDetails(result) {
        let record = result.detail;
        let recordId = record.Id;
        let level = record.HOT_Request__r.IsSerieoppdrag__c ? 'R' : 'WO';
        this.isSeries = record.HOT_Request__r.IsSerieoppdrag__c ? true : false;
        console.log('isSeries: ', this.isSeries);
        if (this.urlStateParameters.level === 'R') {
            level = 'WO';
        }
        this.urlStateParameters.id = recordId;
        this.urlStateParameters.level = level;
        this.setButtonLabels(this.urlStateParameters.level);
        this.refresh();
    }

    setButtonLabels(level) {
        if (this.isSeries && level === 'R') {
            this.editButtonLabel = 'Rediger serie';
            this.copyButtonLabel = 'Kopier serie';
            this.cancelButtonLabel = 'Avlys serie';
        } else {
            this.editButtonLabel = 'Rediger';
            this.copyButtonLabel = 'Kopier';
            this.cancelButtonLabel = 'Avlys';
        }
    }

    goBack() {
        let currentLevel = this.urlStateParameters.level;
        let goThroughRequest = this.workOrder.HOT_Request__r.IsSerieoppdrag__c;
        if (currentLevel === 'WO' && goThroughRequest === true) {
            this.urlStateParameters.level = 'R';
        } else {
            this.urlStateParameters.id = undefined;
            this.urlStateParameters.level = undefined;
        }
        this.refresh();
    }

    refresh() {
        console.log('Refresh');
        this.getRecords();
        this.updateURL();
        this.updateView();
        this.applyFilter({ detail: this.filters });
    }
    updateView() {
        this.isList = this.urlStateParameters.id === undefined;
        this.isRequestDetails = this.urlStateParameters.level === 'R';
        this.isWorkOrderDetails = this.urlStateParameters.level === 'WO';
        this.setButtonLabels(this.urlStateParameters.level);
    }
    updateURL() {
        let refresh = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameters.id !== undefined && this.urlStateParameters.level !== undefined) {
            refresh += '?id=' + this.urlStateParameters.id + '&level=' + this.urlStateParameters.level;
        }
        window.history.pushState({ path: refresh }, '', refresh);
    }
    applyFilter(event) {
        this.filters = event.detail;

        let filteredRecords = [];
        for (let record of this.allRecords) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord *= filter.compare(record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.records = filteredRecords;
    }

    isNavigatingAway = false;
    editButtonLabel = 'Rediger';
    copyButtonLabel = 'Kopier';
    cancelButtonLabel = 'Avlys';
    editOrder() {
        console.log('this.urlStateParameters.level: ', this.urlStateParameters.level);
        this.isNavigatingAway = true;
        console.log(JSON.stringify(this.request));
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'ny-bestilling'
            },
            state: {
                fieldValues: JSON.stringify(this.request),
                fromList: true,
                edit: true
            }
        });
    }

    /*
    editOrder(row) {
        const { Id } = row;
        const index = this.findRowIndexById(Id);
        if (index !== -1) {
            if (row.Orderer__c === this.userRecord.AccountId) {
                this.isGetAllFiles = true;
                if (this.requests[index].ExternalRequestStatus__c.includes('Åpen')) {
                    //Here we should get the entire record from salesforce, to get entire interpretation address.
                    let clone = this.requests[index];
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'ny-bestilling'
                        },
                        state: {
                            fieldValues: JSON.stringify(clone),
                            fromList: true,
                            edit: true
                        }
                    });
                }
            } else {
                alert('Denne bestillingen er bestilt av noen andre, og du har ikke rettigheter til å endre den.');
            }
        }
    } */
}
