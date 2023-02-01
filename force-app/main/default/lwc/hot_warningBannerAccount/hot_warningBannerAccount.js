import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import securityMeasures from '@salesforce/schema/Account.CRM_Person__r.INT_SecurityMeasures__c';
import reservations from '@salesforce/schema/Account.CRM_Person__r.HOT_Reservations__c';
import { formatDate } from 'c/datetimeFormatter';

export default class Hot_warningBannerAccount extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [securityMeasures, reservations]
    })
    record;

    get securityMeasures() {
        let secMeasures = JSON.parse(getFieldValue(this.record.data, securityMeasures));
        let securityMeasuresFormatted = [];
        secMeasures.forEach((sm) => {
            console.log(sm.tiltaksType);
            securityMeasuresFormatted.push(
                sm.beskrivelse +
                    ' (' +
                    sm.tiltaksType +
                    '), gyldig: ' +
                    formatDate(sm.gyldigFraOgMed) +
                    ' - ' +
                    formatDate(sm.gyldigTilOgMed)
            );
        });
        return securityMeasuresFormatted;
    }

    get hasSecurityMeasures() {
        return (
            getFieldValue(this.record.data, securityMeasures) != null &&
            getFieldValue(this.record.data, securityMeasures) != '[]'
        );
    }

    get reservations() {
        return getFieldValue(this.record.data, reservations);
    }

    get hasReservations() {
        return getFieldValue(this.record.data, reservations) != null;
    }
}
