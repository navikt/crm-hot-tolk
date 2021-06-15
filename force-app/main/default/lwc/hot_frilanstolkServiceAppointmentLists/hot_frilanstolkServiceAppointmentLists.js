import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {
    @track activeTab; // = 'open';

    onOpen() {
        const columnLabels = [
            "'Frigitt Dato'",
            "''",
            "'Start Tid'",
            "'Slutt Tid'",
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
            "'Start Tid'",
            "''",
            "'Slutt Tid'",
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
        const columnLabels = ["'Start Tid'", "'Slutt Tid'", "'Poststed'", "'Tema'", "'Arbeidstype'", "''", "''", "''"];
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
            "'Start Tid'",
            "'Slutt Tid'",
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

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'mine-oppdrag'
            },
            state: {
                activeTab: 'wageClaim'
            }
        });
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
