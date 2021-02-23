import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {
    @track activeTab; // = 'open';
    connectedCallback() {
        let testURL = window.location.href;
        //var newURL = parseUri(testURL).searchParams;
        //let newURL = new URL(testURL).searchParams;
        //let newURL = "derp";
        let params = testURL.split('?')[1];

        function parse_query_string(query) {
            var vars = query.split('&');
            var query_string = {};
            for (var i = 0; i < vars.length; i++) {
                var pair = vars[i].split('=');
                var key = decodeURIComponent(pair[0]);
                var value = decodeURIComponent(pair[1]);
                // If first entry with this name
                if (typeof query_string[key] === 'undefined') {
                    query_string[key] = decodeURIComponent(value);
                    // If second entry with this name
                } else if (typeof query_string[key] === 'string') {
                    var arr = [query_string[key], decodeURIComponent(value)];
                    query_string[key] = arr;
                    // If third or later entry with this name
                } else {
                    query_string[key].push(decodeURIComponent(value));
                }
            }
            return query_string;
        }

        if (params != undefined) {
            var parsed_params = parse_query_string(params);

            if (parsed_params.activeTab != null) {
                this.activeTab = parsed_params.activeTab;
                //console.log(parsed_params.activeTab);
                //console.log(this.activeTab);
            }
        }
    }

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

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'mine-oppdrag'
            },
            state: {
                activeTab: 'open'
            }
        });
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

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'mine-oppdrag'
            },
            state: {
                activeTab: 'interested'
            }
        });
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

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'mine-oppdrag'
            },
            state: {
                activeTab: 'my'
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
