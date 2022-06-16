import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyWageClaims from '@salesforce/apex/HOT_WageClaimListController.getMyWageClaims';
//import retractAvailability from '@salesforce/apex/HOT_WageClaimListController.retractAvailability';
import { columns, mobileColumns } from './columns';

export default class Hot_wageClaimList extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    noWageClaims = true;
    @track wageClaims = [];
    @track allWageClaims = [];
    wiredWageClaimsResult;
    @wire(getMyWageClaims)
    wiredWageClaims(result) {
        this.wiredWageClaimsResult = result;
        if (result.data) {
            this.allWageClaims = result.data;
            this.noWageClaims = this.allWageClaims.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.allWageClaims = undefined;
        }
    }

    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredWageClaimsResult);
    }

    /*retractAvailability(row) {
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
    }*/

    setDateFormats() {
        let tempWageClaims = [];
        for (var i = 0; i < this.allWageClaims.length; i++) {
            let tempRec = Object.assign({}, this.allWageClaims[i]);
            tempRec.StartTime__c = this.setDateFormat(this.allWageClaims[i].StartTime__c);
            tempRec.EndTime__c = this.setDateFormat(this.allWageClaims[i].EndTime__c);
            tempWageClaims[i] = tempRec;
        }
        this.wageClaims = tempWageClaims;
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }
}
