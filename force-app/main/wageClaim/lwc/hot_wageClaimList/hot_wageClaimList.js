import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyWageClaims from '@salesforce/apex/HOT_WageClaimListController.getMyWageClaims';
import retractAvailability from '@salesforce/apex/HOT_WageClaimListController.retractAvailability';
import { sortList, getMobileSortingOptions } from 'c/sortController';

export default class Hot_wageClaimList extends LightningElement {
    @track columns = [
        {
            label: 'Start tid',
            fieldName: 'StartTime__c',
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
            label: 'Slutt tid',
            fieldName: 'EndTime__c',
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
            label: 'Døv/Døvblind',
            fieldName: 'DegreeOfHearingAndVisualImpairment__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Oppdragstype',
            fieldName: 'AssignmentType__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Region',
            fieldName: 'ServiceTerritoryName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Arbeidstype',
            fieldName: 'WorkTypeName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Oppdrag',
            fieldName: 'ServiceAppointmentName__c',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];

    mobileColumns = [
        "'Start tid'",
        "'Slutt tid'",
        "'Døv/Døvblind'",
        "'Oppdragstype'",
        "'Region'",
        "'Arbeidstype'",
        "'Oppdrag'"
    ];

    getRowActions(row, doneCallback) {
        let actions = [];
        let tempEndDate = new Date(row['EndTime__c']);
        if (row['Status__c'] === 'Open' && tempEndDate.getTime() > Date.now()) {
            actions.push({ label: 'Tilbaketrekk tilgjengelighet', name: 'retract availability' });
        }

        doneCallback(actions);
    }

    @track wageClaims = [];
    @track allWageClaims = [];
    wiredWageClaimsResult;
    @wire(getMyWageClaims)
    wiredWageClaims(result) {
        console.log(JSON.stringify(result));
        this.wiredWageClaimsResult = result;
        if (result.data) {
            this.allWageClaims = result.data;
            this.error = undefined;
            //console.log(JSON.stringify(this.wageClaims));
            this.filterWageClaims();
        } else if (result.error) {
            this.error = result.error;
            this.allWageClaims = undefined;
        }
    }

    connectedCallback() {
        refreshApex(this.wiredWageClaimsResult);
    }

    //Row action methods
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'retract availability':
                this.retractAvailability(row);
                break;
            default:
        }
    }

    retractAvailability(row) {
        if (
            confirm(
                'Er du sikker på at du vil fjerne tilgjengeligheten din for dette tidspunktet? Du vil da ikke ha krav på lønn.'
            )
        ) {
            try {
                retractAvailability({ recordId: row.Id }).then(() => {
                    refreshApex(this.wiredWageClaimsResult);
                });
            } catch (error) {
                alert(JSON.stringify(error));
            }
        }
    }

    @track choices = [
        { name: 'Ledig på lønn', label: 'Ledig på lønn' },
        { name: 'Lønnskrav', label: 'Lønnskrav' },
        { name: 'Tilbaketrukket', label: 'Tilbaketrukket' },
        { name: 'Alle', label: 'Alle' }
    ];

    @track picklistValue = 'Ledig på lønn';
    handlePicklist(event) {
        this.picklistValue = event.detail;
        this.filterWageClaims();
    }

    filterWageClaims() {
        let tempWageClaim = [];
        for (let i = 0; i < this.allWageClaims.length; i++) {
            if (this.picklistValue === 'Ledig på lønn') {
                if (this.allWageClaims[i].Status__c === 'Open') {
                    tempWageClaim.push(this.allWageClaims[i]);
                }
            } else if (this.picklistValue === 'Lønnskrav') {
                if (this.allWageClaims[i].ServiceAppointment__c !== null) {
                    tempWageClaim.push(this.allWageClaims[i]);
                }
            } else if (this.picklistValue === 'Alle') {
                tempWageClaim.push(this.allWageClaims[i]);
            } else if (this.picklistValue === 'Tilbaketrukket') {
                if (this.allWageClaims[i].Status__c === 'Retracted Availability') {
                    tempWageClaim.push(this.allWageClaims[i]);
                }
            }
        }
        this.wageClaims = tempWageClaim;
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'StartTime__c';

    mobileSortingDefaultValue = '{"fieldName": "StartTime__c", "sortDirection": "asc"} ';
    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    handleMobileSorting(event) {
        let value = JSON.parse(event.detail.value);
        this.sortDirection = value.sortDirection;
        this.sortedBy = value.fieldName;
        this.wageClaims = sortList(this.wageClaims, this.sortedBy, this.sortDirection);
    }
    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.wageClaims = sortList(this.wageClaims, this.sortedBy, this.sortDirection);
    }
}
