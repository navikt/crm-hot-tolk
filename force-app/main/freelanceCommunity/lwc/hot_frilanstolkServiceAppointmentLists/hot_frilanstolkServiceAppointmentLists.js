import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {
    @track activeTab; // = 'open';

    onOpen() {
        const columnLabels = [
            "'Frigitt dato'",
            "''",
            "'Start tid'",
            "'Slutt tid'",
            "'Forespørsel'",
            "'Informasjon'",
            "'Tema'",
            "'Frist"
        ];
        for (var i = 0; i < 10; i++) {
            if (i < columnLabels.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }
    }
    onInterested() {
        const columnLabels = [
            "'Start tid'",
            "''",
            "'Slutt tid'",
            "'Poststed'",
            "'Tema'",
            "'Arbeidstype'",
            "'Status'",
            "'Ny kommentar'"
        ];
        for (var i = 0; i < 10; i++) {
            if (i < columnLabels.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }
    }
    onMy() {
        const columnLabels = ["'Start tid'", "'Slutt tid'", "'Poststed'", "'Tema'", "'Arbeidstype'", "''", "''", "''"];
        for (var i = 0; i < 10; i++) {
            if (i < columnLabels.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }
    }

    onWageClaim() {
        const columnLabels = [
            "'Start tid'",
            "'Slutt tid'",
            "'Oppdragstype'",
            "'Region'",
            "'Arbeidstype'",
            "'Status'",
            "''",
            "''"
        ];
        for (var i = 0; i < 10; i++) {
            if (i < columnLabels.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }
    }

    goToHome(event) {
        if (!this.isProd) {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
    }
}
