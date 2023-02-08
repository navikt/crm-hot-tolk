import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class hot_userInformation extends NavigationMixin(LightningElement) {
    @track breadcrumbs = [];
    connectedCallback() {
        this.breadcrumbs = [
            {
                label: 'Tolketjenesten',
                href: ''
            },
            {
                label: 'Min side',
                href: 'mine-side'
            }
        ];
    }

    renderedCallback() {
        this.template.querySelector('h2').focus();
    }
}
