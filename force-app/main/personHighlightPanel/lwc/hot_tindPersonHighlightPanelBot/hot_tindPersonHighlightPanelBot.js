import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class hot_personHighlightPanelBot extends NavigationMixin(LightningElement) {
    @api recordId;
    @api personDetails;
    @api modalTitle = '';

    isModalOpen = false;
    currentFlow;
    fnr;

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
            this.closeModal();
        }
    }

    handleEditRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'edit'
            }
        });
    }
    get isDisabledButtons() {
        return !this.personDetails?.fullName;
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
