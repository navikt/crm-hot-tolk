import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class hot_tindRequestHighlightPanelTop extends NavigationMixin(LightningElement) {
    @api requestDetails;
    accountUrl = '#';
    connectedCallback() {
        if (this.requestDetails?.Account__c) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Account',
                    recordId: this.requestDetails.Account__c,
                    actionName: 'view'
                }
            }).then((url) => {
                this.accountUrl = url;
            });
        }
    }

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

    get formattedFullName() {
        return this.requestDetails?.Account__r?.Name ?? '';
    }

    get personIdent() {
        return this.requestDetails?.Account__r?.INT_PersonIdent__c ?? '';
    }

    get requestName() {
        return this.requestDetails?.Name;
    }
    get formattedRequestInfo() {
        return [
            this.requestDetails?.Subject__c,
            this.requestDetails?.Status__c,
            this.requestDetails?.InterpretationMethod__r?.Name,
            this.requestDetails?.StartTime__c
                ? new Date(this.requestDetails.StartTime__c).toLocaleString('no-NO', {
                      dateStyle: 'short',
                      timeStyle: 'short'
                  })
                : null,
            this.requestDetails?.IsSerieoppdrag__c ? 'Serieoppdrag' : null
        ]
            .filter(Boolean)
            .join(' / ');
    }
    get accountHref() {
        return this.accountUrl;
    }
}
