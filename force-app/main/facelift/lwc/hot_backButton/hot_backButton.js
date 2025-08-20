import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_backButton extends NavigationMixin(LightningElement) {
    @api urlStateParameters;
    @api workOrder;
    @api isSeries; // Whether the request is a series

    goBack() {
        try {
            const url = new URL(window.location.href);
            const pathname = url.pathname.toLowerCase();
            const searchParams = url.searchParams;

            if (pathname.includes('/s/mine-oppdrag') || pathname.includes('/s/mine-samtaler-frilanstolk')) {
                this.navigateHome();
                return;
            }

            if (this.urlStateParameters) {
                if (this.urlStateParameters.from === 'mine-varsler') {
                    this.navigateToPage('mine-varsler');
                    return;
                }
                if (this.urlStateParameters.from === 'mine-samtaler') {
                    this.navigateToPage('mine-samtaler');
                    return;
                }

                const currentLevel = this.urlStateParameters.level;
                if (!currentLevel) {
                    this.navigateHome();
                    return;
                }

                this.urlStateParameters.id = '';
                this.urlStateParameters.level = '';
                this.refresh(true);
                return;
            }

            if (pathname.includes('/s/mine-bestillinger') && searchParams.has('id') && searchParams.has('level')) {
                const pageName = pathname.includes('/s/mine-bestillinger-andre')
                    ? 'mine-bestillinger-andre'
                    : 'mine-bestillinger';
                const id = searchParams.get('id');
                const level = searchParams.get('level');

                if (level === 'R') {
                    this.navigateToPage(pageName);
                } else if (level === 'WO') {
                    if (this.isSeries) {
                        this.navigateToPageWithParams(pageName, { id, level: 'R' });
                    } else {
                        this.navigateToPage(pageName);
                    }
                }
                return;
            }

            //  Fallback: Always go home
            this.navigateHome();
        } catch (e) {
            this.navigateHome();
        }
    }

    navigateHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { pageName: 'home' }
        });
    }

    navigateToPage(pageName) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { pageName }
        });
    }

    navigateToPageWithParams(pageName, params) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { pageName },
            state: params
        });
    }

    refresh(force) {
        this.dispatchEvent(new CustomEvent('refresh', { detail: { force } }));
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.goBack();
        }
    }
}
