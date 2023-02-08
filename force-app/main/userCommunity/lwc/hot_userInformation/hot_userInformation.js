import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class hot_userInformation extends NavigationMixin(LightningElement) {
    @track breadcrumbs = [];
    connectedCallback() {
        document.body.scrollIntoView({ behavior: 'smooth', block: 'start' });
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
}
