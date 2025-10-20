// @ts-nocheck
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import guardianships from './hot_guardianships.html';
import powerOfAttorneys from './hot_powerOfAttorneys.html';
import hotPersonHighlightPanelBadgeContent from './hot_personPanelBadgeContent.html';
import historicalPowerOfAttorney from './hot_historicalPowerOfAttorney.html';
import sharedStyling from './hot_sharedStyling.css';

const templates = {
    GuardianshipOrFuturePowerOfAttorney: guardianships,
    PowerOfAttorney: powerOfAttorneys,
    historicalPowerOfAttorney: historicalPowerOfAttorney
};

export default class hot_personHighlightPanelBadgeContent extends NavigationMixin(LightningElement) {
    @api type;
    @api badgeData;
    @api shownBadge;
    // In LWC you can import stylesheets to apply to all templates
    // https://developer.salesforce.com/docs/platform/lwc/guide/create-components-css.html#assign-css-stylesheets-to-a-component
    static stylesheets = [sharedStyling];

    render() {
        //code
        return templates[this.type] != null ? templates[this.type] : hotPersonHighlightPanelBadgeContent;
    }

    connectedCallback() {
        window.addEventListener('resize', this.calculateBadgeContent.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.calculateBadgeContent.bind(this));
    }

    renderedCallback() {
        this.calculateBadgeContent();
    }

    calculateBadgeContent() {
        const renderedBadgeContent = this.template.querySelector('.backgroundStyling');
        if (!renderedBadgeContent) return;
        renderedBadgeContent.style.removeProperty('right');
        renderedBadgeContent.style.removeProperty('left');
        if (renderedBadgeContent.offsetWidth + renderedBadgeContent.getBoundingClientRect().left >= window.innerWidth) {
            renderedBadgeContent.style.right = 0;
            renderedBadgeContent.style.left = 'auto';
        } else {
            renderedBadgeContent.style.right = 'auto';
            renderedBadgeContent.style.removeProperty('left');
        }
    }

    get showBadge() {
        if (this.type === this.shownBadge) console.log(JSON.stringify(this.badgeData));
        return this.type === this.shownBadge;
    }
}
