import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_backButton extends NavigationMixin(LightningElement) {
    @api fullWidth = false;
    @api navigationTarget;

    goBack() {
        if (this.navigationTarget) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.navigationTarget
                }
            });
        } else {
            window.history.back();
        }
    }
    get containerClass() {
        return this.fullWidth ? 'full-width-container' : 'inline-container';
    }
}
