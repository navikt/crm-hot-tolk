import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_backButton extends NavigationMixin(LightningElement) {
    @api ariaLabel;
    @api destinationLabel = 'Hjem';
    @api fallbackUrl = '/tolketjenesten/s/';

    get computedAriaLabel() {
        return this.ariaLabel || `Tilbake til ${this.destinationLabel}`;
    }
    get computedDestinationLabel() {
        return this.destinationLabel;
    }

    goBack = () => {
        const evt = new CustomEvent('back', { cancelable: true, detail: {} });
        const notCanceled = this.dispatchEvent(evt);
        if (!notCanceled) return; // parent handled it

        const { pathname = '', search = '', hash = '' } = window.location || {};
        const lowerPath = pathname.toLowerCase();

        const isExactMineBestillinger = /\/s\/mine-bestillinger\/?$/i.test(lowerPath) && search === '' && hash === '';
        const isExactMineBestillingerAndre =
            /\/s\/mine-bestillinger-andre\/?$/i.test(lowerPath) && search === '' && hash === '';
        const isMineOppdrag = lowerPath.includes('/s/mine-oppdrag');

        if (isExactMineBestillinger || isMineOppdrag || isExactMineBestillingerAndre) {
            this.navigateHome();
            return;
        }

        try {
            if (window.history && window.history.length > 1) {
                window.history.back();
                return;
            }
        } catch (e) {}

        // Fallback if no history
        if (this.fallbackUrl) {
            window.location.assign(this.fallbackUrl);
        }
    };

    handleKeyDown = (e) => {
        if (e.key === 'Enter' || e.key === ' ' || e.keyCode === 13 || e.keyCode === 32) {
            e.preventDefault();
            this.goBack();
        }
    };

    navigateHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { pageName: 'home' }
        });
    }
}
