import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class hot_userInformation extends NavigationMixin(LightningElement) {
    goToMyPage() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'min-side-freelance'
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
