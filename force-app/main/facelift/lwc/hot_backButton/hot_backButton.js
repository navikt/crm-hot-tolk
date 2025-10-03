import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import icons from '@salesforce/resourceUrl/ikoner';

const PAGE_LABELS = {
    home: 'Hjem',
    'frilanstolk-min-side': 'Mine side som frilans',
    'min-side': 'Mine side',
    'mine-oppdrag': 'Mine oppdrag',
    'mine-samtaler': 'Mine samtaler',
    'mine-samtaler-frilanstolk': 'Mine samtaler som frilans',
    'mine-bestillinger': 'Mine bestillinger',
    'mine-bestillinger-andre': 'Bestillinger på vegne av andre'
};

function pageLabel(name) {
    if (!name) return null;
    const key = String(name).toLowerCase().trim();
    return PAGE_LABELS[key] || null;
}

export default class Hot_backButton extends NavigationMixin(LightningElement) {
    homeIcon = icons + '/Home/Home.svg';
    leftArrowIcon = icons + '/Left/Left.svg';
    @api ariaLabel;
    @api destinationLabel;
    @api fallbackUrl;
    @api isSeries = false;

    _urlStateParameters = { level: '', id: '' };
    @api
    get urlStateParameters() {
        return this._urlStateParameters;
    }
    set urlStateParameters(v) {
        this._urlStateParameters = { ...(v || { level: '', id: '' }) };
    }

    get computedDestinationLabel() {
        return this.destinationLabel || this.deriveDestinationFromContext() || 'forrige side';
    }

    get computedAriaLabel() {
        return `Tilbake til ${this.computedDestinationLabel}`;
    }

    deriveDestinationFromContext() {
        try {
            const url = new URL(window.location.href);
            const pathname = url.pathname.toLowerCase();
            const searchParams = url.searchParams;

            if (pathname.includes('/s/thread')) {
                const from = searchParams.get('from');
                const recordId = searchParams.get('recordId');
                const level = searchParams.get('level');
                if (from && recordId && level) return pageLabel(from) || 'tråden';
                return 'tråden';
            }

            if (
                pathname.includes('/s/mine-oppdrag') ||
                pathname.includes('/s/mine-samtaler-frilanstolk') ||
                pathname.includes('/s/mine-samtaler') ||
                pathname.includes('/s/frilanstolk-min-side') ||
                pathname.includes('/s/min-side')
            ) {
                return pageLabel('home');
            }

            if (this._urlStateParameters && this._urlStateParameters.from) {
                const lbl = pageLabel(this._urlStateParameters.from);
                if (lbl) return lbl;
                if (!this._urlStateParameters.level) return pageLabel('home');
            }

            const fromParam = searchParams.get('from');
            if (fromParam) {
                if (fromParam === 'mine-varsler') return pageLabel('home');
                const known = ['mine-samtaler-frilanstolk', 'mine-samtaler', 'mine-oppdrag'];
                if (known.includes(fromParam)) return pageLabel(fromParam);
            }

            if (pathname.includes('/s/mine-bestillinger')) {
                const pageName = pathname.includes('/s/mine-bestillinger-andre')
                    ? 'mine-bestillinger-andre'
                    : 'mine-bestillinger';

                const level = (this._urlStateParameters && this._urlStateParameters.level) || searchParams.get('level');

                if (this.isSeries && level === 'WO') {
                    return 'hoved bestilling fra serien';
                }
                if (level) return pageLabel(pageName);
                return pageLabel('home');
            }

            return null;
        } catch (e) {
            return 'Hjem';
        }
    }

    goBack = () => {
        const evt = new CustomEvent('back', { cancelable: true, detail: {} });
        const notCanceled = this.dispatchEvent(evt);
        if (!notCanceled) return;

        const { pathname = '', search = '', hash = '' } = window.location || {};
        const lowerPath = pathname.toLowerCase();

        const isExactMineBestillinger = /\/s\/mine-bestillinger\/?$/i.test(lowerPath) && search === '' && hash === '';
        const isExactMineBestillingerAndre =
            /\/s\/mine-bestillinger-andre\/?$/i.test(lowerPath) && search === '' && hash === '';
        const isMineOppdrag = lowerPath.includes('/s/mine-oppdrag');

        if (isExactMineBestillinger || isExactMineBestillingerAndre || isMineOppdrag) {
            this.navigateHome();
            return;
        }

        try {
            if (window.history && window.history.length > 1) {
                window.history.back();
                return;
            }
        } catch (e) {
            // fall through
        }

        // Fallback if no history
        if (this.fallbackUrl) {
            window.location.assign(this.fallbackUrl);
        }
    };

    handleKeyDownBack = (e) => {
        if (e.key === 'Enter' || e.key === ' ' || e.keyCode === 13 || e.keyCode === 32) {
            e.preventDefault();
            this.goBack();
        }
    };
    handleKeyDownHome() {
        this.navigateHome();
    }

    navigateHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { pageName: 'home' }
        });
    }
}
