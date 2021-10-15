import { LightningElement, wire, track } from 'lwc';
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
            label: 'Status',
            fieldName: 'Status__c',
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
        "'Oppdrag'",
        "'Status'"
    ];

    getRowActions(row, doneCallback) {
        let actions = [];
        let tempEndDate = new Date(row['EndTime__c']);
        if (row['Status__c'] === 'Åpen' && tempEndDate.getTime() > Date.now()) {
            actions.push({ label: 'Tilbaketrekk tilgjengelighet', name: 'retract availability' });
        }

        doneCallback(actions);
    }

    @track wageClaims = [];
    @track allWageClaims = [];
    wiredWageClaimsResult;
    @wire(getMyWageClaims)
    wiredWageClaims(result) {
        this.wiredWageClaimsResult = result;
        if (result.data) {
            this.allWageClaims = result.data;
            this.error = undefined;
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
        if (actionName == 'retract availability') {
            this.retractAvailability(row);
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
        { name: 'Tilbaketrukket', label: 'Tilbaketrukket' },
        { name: 'Alle', label: 'Alle' }
    ];

    @track picklistValue = 'Ledig på lønn';
    handlePicklist(event) {
        this.picklistValue = event.detail.name;
        this.filterWageClaims();
    }

    filterWageClaims() {
        let tempWageClaim = [];
        for (let wageClaim of this.allWageClaims) {
            if (this.picklistValue === 'Ledig på lønn') {
                if (wageClaim.Status__c === 'Åpen') {
                    tempWageClaim.push(wageClaim);
                }
            } else if (this.picklistValue === 'Alle') {
                tempWageClaim.push(wageClaim);
            } else if (this.picklistValue === 'Tilbaketrukket') {
                if (wageClaim.Status__c === 'Tilbaketrukket tilgjengelighet') {
                    tempWageClaim.push(wageClaim);
                }
            }
        }
        this.wageClaims = tempWageClaim;
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'StartTime__c';

    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.wageClaims = sortList(this.wageClaims, this.sortedBy, this.sortDirection);
    }
}
