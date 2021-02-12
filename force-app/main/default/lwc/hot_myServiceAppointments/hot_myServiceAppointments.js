import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';

var actions = [{ label: 'Detaljer', name: 'details' }];

export default class Hot_myServiceAppointments extends LightningElement {
    @track columns = [
        {
            label: 'Start Tid',
            fieldName: 'EarliestStartTime',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {
            label: 'Slutt Tid',
            fieldName: 'DueDate',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {
            label: 'Poststed',
            fieldName: 'City',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tema',
            fieldName: 'Subject',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tolkemetode',
            fieldName: 'HOT_WorkTypeName__c',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: actions }
        }
    ];

    @track serviceResource;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }

    @track myServiceAppointments;
    @track myServiceAppointmentsFiltered;
    wiredMyServiceAppointmentsResult;
    @wire(getMyServiceAppointments)
    wiredMyServiceAppointments(result) {
        console.log('wiredMyServiceAppointments');
        this.wiredMyServiceAppointmentsResult = result;
        if (result.data) {
            this.myServiceAppointments = result.data;
            this.error = undefined;
            console.log(JSON.stringify(this.myServiceAppointments));
            this.filterServiceAppointments();
            console.log(JSON.stringify(this.myServiceAppointmentsFiltered));
        } else if (result.error) {
            this.error = result.error;
            this.myServiceAppointments = undefined;
        }
    }

    filterServiceAppointments() {
        console.log('filterServiceAppointments');
        var tempServiceAppointments = [];
        for (var i = 0; i < this.myServiceAppointments.length; i++) {
            if (
                this.myServiceAppointments[i].Status != 'Avlyst' &&
                this.myServiceAppointments[i].Status != 'Udekket' &&
                this.myServiceAppointments[i].Status != 'Dekket'
            ) {
                tempServiceAppointments.push(this.myServiceAppointments[i]);
            }
        }
        this.myServiceAppointmentsFiltered = tempServiceAppointments;
    }

    showHideAll() {
        if (this.isChecked) {
            this.myServiceAppointmentsFiltered = this.myServiceAppointments;
        } else {
            this.filterServiceAppointments();
        }
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'EarliestStartTime';

    mobileSortingDefaultValue =
        '{"fieldName": "EarliestStartTime", "sortDirection": "asc"} ';
    get sortingOptions() {
        return [
            {
                label: 'Start tid stigende',
                value:
                    '{"fieldName": "EarliestStartTime", "sortDirection": "asc"} '
            },
            {
                label: 'Start tid synkende',
                value:
                    '{"fieldName": "EarliestStartTime", "sortDirection": "desc"} '
            },
            {
                label: 'Slutt tid stigende',
                value: '{"fieldName": "DueDate", "sortDirection": "asc"} '
            },
            {
                label: 'Slutt tid synkende',
                value: '{"fieldName": "DueDate", "sortDirection": "desc"} '
            },
            {
                label: 'Poststed A - Å',
                value: '{"fieldName": "City", "sortDirection": "asc"} '
            },
            {
                label: 'Poststed A - Å',
                value: '{"fieldName": "City", "sortDirection": "desc"} '
            },
            {
                label: 'Tema A - Å',
                value:
                    '{"fieldName": "HOT_FreelanceSubject__c", "sortDirection": "asc"} '
            },
            {
                label: 'Tema A - Å',
                value:
                    '{"fieldName": "HOT_FreelanceSubject__c", "sortDirection": "desc"} '
            },
            {
                label: 'Arbeidstype A - Å',
                value:
                    '{"fieldName": "HOT_WorkTypeName__c", "sortDirection": "asc"} '
            },
            {
                label: 'Arbeidstype Å - A',
                value:
                    '{"fieldName": "HOT_WorkTypeName__c", "sortDirection": "desc"} '
            }
        ];
    }
    handleMobileSorting(event) {
        this.sortList(JSON.parse(event.detail.value));
    }
    sortBy(field, reverse) {
        const key = function (x) {
            return x[field];
        };
        if (field == 'HOT_NumberOfInterestedResources__c') {
            return function (a, b) {
                a = key(a);
                b = key(b);
                return reverse * ((a > b) - (b > a));
            };
        } else {
            return function (a, b) {
                a = key(a).toLowerCase();
                b = key(b).toLowerCase();
                return reverse * ((a > b) - (b > a));
            };
        }
    }
    onHandleSort(event) {
        this.sortList(event.detail);
    }
    sortList(input) {
        const { fieldName: sortedBy, sortDirection } = input;
        let cloneData = [...this.myServiceAppointments];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

        this.myServiceAppointments = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
        this.showHideAll();
    }

    //Row action methods
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'details':
                this.showDetails(row);
                break;
            default:
        }
    }

    @track recordId;
    @track record;
    @track isDetails = false;
    showDetails(row) {
        console.log('showDetails');
        this.recordId = row.Id;
        this.isDetails = true;
        this.record = row;
    }
    abortShowDetails() {
        this.isDetails = false;
    }

    isChecked = false;
    handleChecked(event) {
        this.isChecked = event.detail.checked;
        if (this.isChecked) {
            this.myServiceAppointmentsFiltered = this.myServiceAppointments;
        } else {
            this.filterServiceAppointments();
        }
    }
}
