import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getAllPermissions from '@salesforce/apex/HOT_CheckPermissions.getAllPermissions';

export default class hot_personHighlightPanelBot extends NavigationMixin(LightningElement) {
    @api recordId;
    @api personDetails;
    @api modalTitle = '';

    isModalOpen = false;
    currentFlow;
    fnr;
    hasPermissionToCreateFreelance = false;
    isFormidler = false;
    isFormidlerAdmin = false;
    isAdmin = false;

    handleFlowButton(event) {
        this.currentFlow = event.target.dataset.flow;
        this.modalTitle = `Run ${this.currentFlow}`;
        this.isModalOpen = true;
        setTimeout(() => {
            const flow = this.template.querySelector('lightning-flow');
            if (flow) {
                flow.startFlow(this.currentFlow, [
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    }
                ]);
            }
        }, 0);
    }

    closeModal() {
        this.isModalOpen = false;
        this.currentFlow = null;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            if (this.currentFlow === 'HOT_OverrideKRRMobilePhoneNumber') {
                window.location.reload();
            } else {
                this.closeModal();
            }
        }
    }

    // handleEditRecord() {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: this.recordId,
    //             actionName: 'edit'
    //         }
    //     });
    // }

    get showButtons() {
        return (this.personDetails?.fullName && this.isFormidler) || this.isAdmin;
    }

    @wire(getAllPermissions)
    wiredPermissions({ error, data }) {
        if (data) {
            this.hasPermissionToCreateFreelance = data.hasFreelancePermission;
            this.isFormidler = data.isFormidler;
            this.isFormidlerAdmin = data.isFormidlerAdmin;
            this.isAdmin = data.isAdmin;

            console.log('Permissions:', data);
        }
        if (error) {
            console.error('Error fetching permissions:', error);
        }
    }

    handleButtonClick(event) {
        var fagsystem = event.currentTarget.dataset.id;
        var url = this.generateUrl(fagsystem);
        console.log(url);

        //gå til url her
        window.open(url);
    }
    generateUrl(fagsystem) {
        switch (fagsystem) {
            case 'gosys':
                return `https://gosys.intern.nav.no/gosys/personoversikt/fnr=${this.personDetails.personIdent}`;
            default:
                return null;
        }
    }
}
