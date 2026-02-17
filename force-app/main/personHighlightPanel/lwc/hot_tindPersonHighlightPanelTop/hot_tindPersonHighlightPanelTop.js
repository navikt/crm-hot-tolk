import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import NAV_ICONS from '@salesforce/resourceUrl/HOT_tindIcons';

import getTolketjenesten from '@salesforce/apex/HOT_GetTolketjeneste.getTolketjeneste';

export default class hot_personHighlightPanelTop extends LightningElement {
    @api recordId;
    @api personDetails;
    navUnitName;
    error;

    handleCopy(event) {
        const eventValue = event.currentTarget.value;

        // Copy logic
        const hiddenInput = document.createElement('input');
        hiddenInput.value = eventValue;
        document.body.appendChild(hiddenInput);
        hiddenInput.select();

        try {
            const successful = document.execCommand('copy');
            if (successful) {
                this.showCopyToast('success');
            } else {
                this.showCopyToast('error');
            }
        } catch (error) {
            this.showCopyToast('error');
        }
        document.body.removeChild(hiddenInput);
        event.currentTarget.focus();
    }

    showCopyToast(status) {
        const evt = new ShowToastEvent({
            message: status === 'success' ? 'kopiert til utklippstavlen.' : 'Kunne ikke kopiere',
            variant: status,
            mode: 'pester'
        });
        this.dispatchEvent(evt);
    }

    @wire(getTolketjenesten, {
        recordId: '$recordId',
        objectApiName: 'Account'
    })
    wiredTolketjenesten({ error, data }) {
        if (data) {
            this.navUnitName = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.name = undefined;
            console.error('getTolketjenesten error:', error);
        }
    }

    get formattedPersonInfo() {
        return [
            this.personDetails?.age,
            this.personDetails?.vedtak,
            this.personDetails?.citizenship,
            this.personDetails?.legalStatus,
            this.navUnitName
        ]
            .filter(Boolean)
            .join(' / ');
    }

    get formattedFullName() {
        if (!this.personDetails?.fullName) {
            return 'Skjermet person';
        }
        return this.personDetails?.isDeceased ? this.personDetails?.fullName + ' (død)' : this.personDetails?.fullName;
    }

    get genderIcon() {
        if (!this.personDetails?.fullName) return 'confidentialCircleFilled';
        switch (this.personDetails?.gender) {
            case 'Mann':
                return 'MaleCircleFilled';
            case 'Kvinne':
                return 'FemaleCircleFilled';
            default:
                return 'UnknownCircleFilled';
        }
    }

    get genderText() {
        if (this.personDetails?.gender === 'Ukjent') return 'Ukjent kjønn';
        return this.personDetails?.gender;
    }

    get genderIconSrc() {
        return NAV_ICONS + '/' + this.genderIcon + '.svg#' + this.genderIcon;
    }

    get personIdent() {
        return this.personDetails?.personIdent;
    }
}
