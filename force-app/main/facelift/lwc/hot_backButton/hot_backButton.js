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

            // Handle thread pages dynamically
            if (pathname.includes('/s/thread')) {
                const from = searchParams.get('from');
                const recordId = searchParams.get('recordId');
                const level = searchParams.get('level');

                if (from && from.startsWith('mine-bestillinger') && recordId && level) {
                    this.navigateToPageWithParams(from, { id: recordId, level });
                    return;
                }
            }

            //  Handle special pages that always go home
            if (pathname.includes('/s/mine-oppdrag') || pathname.includes('/s/mine-samtaler-frilanstolk')) {
                this.navigateHome();
                return;
            }

            // Handle navigation based on urlStateParameters
            if (this.urlStateParameters && this.urlStateParameters.from) {
                this.handleFromPage(this.urlStateParameters.from);
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

            // Handle navigation based on URL search params
            const fromParam = searchParams.get('from');
            if (fromParam) {
                // If fromParam matches known pages
                const knownPages = ['mine-samtaler-frilanstolk', 'mine-samtaler', 'mine-oppdrag'];
                if (knownPages.includes(fromParam)) {
                    this.navigateToPage(fromParam);
                    return;
                }
            }

            // Handle mine-bestillinger pages
            if (pathname.includes('/s/mine-bestillinger')) {
                const pageName = pathname.includes('/s/mine-bestillinger-andre')
                    ? 'mine-bestillinger-andre'
                    : 'mine-bestillinger';

                const id = searchParams.get('id');
                const level = searchParams.get('level');

                if (id && level) {
                    if (level === 'R') {
                        this.navigateToPageWithParams(pageName, {});
                    } else if (level === 'WO') {
                        this.navigateToPageWithParams(pageName, this.isSeries ? { id, level: 'R' } : {});
                    }
                    return;
                }
            }

            // Fallback to home
            this.navigateHome();
        } catch (e) {
            this.navigateHome();
        }
    }

    // Helper to navigate based on 'from'
    handleFromPage(from) {
        const pageMapping = {
            'mine-varsler': 'mine-varsler',
            'mine-samtaler': 'mine-samtaler',
            'mine-samtaler-frilanstolk': 'mine-samtaler-frilanstolk'
        };
        if (pageMapping[from]) {
            this.navigateToPage(pageMapping[from]);
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
