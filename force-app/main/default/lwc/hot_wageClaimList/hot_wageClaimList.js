import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyWageClaims from '@salesforce/apex/HOT_WageClaimListController.getMyWageClaims';
import retractAvailability from '@salesforce/apex/HOT_WageClaimListController.retractAvailability';

var actions = [{ label: 'Tilbaketrekk tilgjengelighet', name: 'retract availability' }];

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
            label: 'Status',
            fieldName: 'Status__c',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: actions }
        }
    ];

    @track wageClaims;
    wiredWageClaimsResult;
    @wire(getMyWageClaims)
    wiredWageClaims(result) {
        console.log(JSON.stringify(result));
        this.wiredWageClaimsResult = result;
        if (result.data) {
            this.wageClaims = result.data;
            this.error = undefined;
            //console.log(JSON.stringify(this.wageClaims));
        } else if (result.error) {
            this.error = result.error;
            this.wageClaims = undefined;
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
}
