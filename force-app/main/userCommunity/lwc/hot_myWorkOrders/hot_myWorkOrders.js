import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import STATUS from '@salesforce/schema/WorkOrder.Status';
import NOTIFY_DISPATCHER from '@salesforce/schema/WorkOrder.HOT_IsNotifyDispatcher__c';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import WORKORDER_ID from '@salesforce/schema/WorkOrder.Id';
import getWorkOrdersFromRequest from '@salesforce/apex/HOT_WorkOrderListController.getWorkOrdersFromRequest';
import getMyWorkOrders from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrders';
import { sortList, getMobileSortingOptions } from 'c/sortController';
import { workOrderFieldLabels } from 'c/hot_fieldLabels';
import { formatRecord } from 'c/hot_recordDetails';

export default class Hot_myWorkOrders extends NavigationMixin(LightningElement) {
    @track columns = [
        {
            label: 'Start tid',
            fieldName: 'StartDate',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            },
            initialWidth: 135
        },
        {
            label: 'Slutt tid',
            fieldName: 'EndDate',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            },
            initialWidth: 135
        },
        {
            label: 'Tema',
            fieldName: 'Subject',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Bestillingsnr',
            fieldName: 'HOT_RequestName__c',
            type: 'text',
            sortable: true,
            initialWidth: 130
        },
        {
            label: 'Status',
            fieldName: 'HOT_ExternalWorkOrderStatus__c',
            type: 'text',
            sortable: true,
            initialWidth: 150
        },
        {
            label: 'Tolker',
            fieldName: 'HOT_Interpreters__c',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];
    getRowActions(row, doneCallback) {
        let actions = [];
        if (row.HOT_IsCancelable__c) {
            actions.push({ label: 'Avlys', name: 'delete' });
        }
        actions.push({ label: 'Detaljer', name: 'details' });
        doneCallback(actions);
    }

    columnLabels = ["'Start tid'", "'Slutt tid'", "'Tema'", "'Bestillingsnummer'", "'Status'", "'Tolker'", "''"];

    wiredWorkOrderResult;
    @track workOrders = [];
    @track requestNumber;
    @wire(getMyWorkOrders)
    wiredGetMyWorkOrders(result) {
        if (result.data && this.showAll) {
            this.workOrders = result.data;
            this.wiredWorkOrderResult = result;
        }
    }
    @wire(getWorkOrdersFromRequest, { requestNumber: '$requestNumber' })
    wiredGetWorkOrdersFromRequest(result) {
        if (result.data && !this.showAll) {
            this.workOrders = result.data;
            this.wiredWorkOrderResult = result;
        }
    }

    @track showAll = true;
    connectedCallback() {
        for (let i = 0; i < 10; i++) {
            if (i < this.columnLabels.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), this.columnLabels[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }

        let testURL = window.location.href;
        let params = testURL.split('?')[1];

        function parse_query_string(query) {
            let vars = query.split('&');
            let query_string = {};
            for (let i = 0; i < vars.length; i++) {
                let pair = vars[i].split('=');
                let key = decodeURIComponent(pair[0]);
                let value = decodeURIComponent(pair[1]);
                // If first entry with this name
                if (typeof query_string[key] === 'undefined') {
                    query_string[key] = decodeURIComponent(value);
                    // If second entry with this name
                } else if (typeof query_string[key] === 'string') {
                    let arr = [query_string[key], decodeURIComponent(value)];
                    query_string[key] = arr;
                    // If third or later entry with this name
                } else {
                    query_string[key].push(decodeURIComponent(value));
                }
            }
            return query_string;
        }

        if (params != undefined) {
            let parsed_params = parse_query_string(params);
            if (parsed_params.id != null) {
                this.requestNumber = parsed_params.id;
            }
            this.showAll = false;
        } else {
            this.showAll = true;
        }
    }

    goToHome(event) {
        if (!this.isProd) {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
    }

    goToMyWorkOrders(event) {
        if (!this.isProd) {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'min-tidsplan'
                }
            });
        }
    }
    goToMyRequests(event) {
        if (!this.isProd) {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-bestillinger'
                }
            });
        }
    }
    @track thisURL = window.location.href;

    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'StartDate';

    mobileSortingDefaultValue = '{"fieldName": "StartDate", "sortDirection": "asc"} ';
    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }
    handleMobileSorting(event) {
        this.sortDirection = event.detail.value.sortDirection;
        this.sortedBy = event.detail.value.fieldName;
        this.workOrders = sortList(this.workOrders, this.sortedBy, this.sortDirection);
    }
    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.workOrders = sortList(this.workOrders, this.sortedBy, this.sortDirection);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'delete':
                this.cancelWorkOrder(row);
                break;
            case 'details':
                this.showDetails(row);
                break;
            default:
                break;
        }
    }

    @track isDetails = false;
    @track workOrderDetails = null;
    showDetails(row) {
        this.workOrderDetails = formatRecord(row, workOrderFieldLabels);
        let detailPage = this.template.querySelector('.detailPage');
        detailPage.classList.remove('hidden');
        detailPage.focus();
    }

    abortShowDetails() {
        this.template.querySelector('.detailPage').classList.add('hidden');
    }

    cancelWorkOrder(row) {
        const { Id } = row;
        console.log(JSON.stringify(this.workOrders));
        const index = this.findRowIndexById(Id);
        console.log(index);
        if (index !== -1) {
            console.log('index != -1');
            if (
                this.workOrders[index].HOT_ExternalWorkOrderStatus__c !== 'Avlyst' &&
                this.workOrders[index].HOT_ExternalWorkOrderStatus__c !== 'Dekket'
            ) {
                console.log('confirm');
                if (confirm('Er du sikker på at du vil avlyse?')) {
                    const fields = {};
                    fields[WORKORDER_ID.fieldApiName] = Id;
                    fields[STATUS.fieldApiName] = 'Canceled';
                    fields[NOTIFY_DISPATCHER.fieldApiName] = true;
                    const recordInput = { fields };
                    updateRecord(recordInput)
                        .then(() => {
                            refreshApex(this.wiredWorkOrderResult);
                        })
                        .catch((error) => {
                            alert('Kunne ikke avlyse.');
                        });
                }
            } else {
                alert('Du kan ikke avlyse denne bestillingen.');
            }
        }
    }
    findRowIndexById(Id) {
        let ret = -1;
        this.workOrders.some((row, index) => {
            if (row.Id === Id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }
}
