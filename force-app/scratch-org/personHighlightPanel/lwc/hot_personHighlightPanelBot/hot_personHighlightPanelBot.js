import { LightningElement, api } from 'lwc';

export default class hot_personHighlightPanelBot extends LightningElement {
    @api personDetails;

    actorId;
    fnr;

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
