import { LightningElement, api } from 'lwc';
import informationTemplate from './information.html';
import warningTemplate from './warning.html';

import ICON_ExclamationmarkWhite from '@salesforce/resourceUrl/ExclamationmarkWhite';
import ICON_Exclamationmark from '@salesforce/resourceUrl/Exclamationmark';
import ICON_ExclamationmarkTriangleWhite from '@salesforce/resourceUrl/ExclamationmarkTriangleWhite';
import ICON_ChevronUpWhite from '@salesforce/resourceUrl/ChevronUpWhite';
import ICON_ChevronDownWhite from '@salesforce/resourceUrl/ChevronDownWhite';

export default class Hot_announcement extends LightningElement {
    ExclamationmarkIcon = ICON_Exclamationmark;
    ExclamationmarkWhiteIcon = ICON_ExclamationmarkWhite;
    ExclamationmarkTriangleWhiteIcon = ICON_ExclamationmarkTriangleWhite;
    ChevronUpWhiteIcon = ICON_ChevronUpWhite;
    ChevronDownWhiteIcon = ICON_ChevronDownWhite;

    @api announcement;

    expanded = false;

    get title() {
        return this.announcement?.Title__c || '';
    }

    get description() {
        return this.announcement?.Description__c || '';
    }

    get chevronIcon() {
        return this.expanded ? this.ChevronUpWhiteIcon : this.ChevronDownWhiteIcon;
    }

    get descriptionClass() {
        return `description-wrapper ${this.expanded ? 'expanded' : 'collapsed'}`;
    }

    toggleExpand() {
        this.expanded = !this.expanded;
    }

    handleKeydown(event) {
        // Lar brukeren utvide/lukke med Enter eller Space
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.toggleExpand();
        }
    }

    render() {
        if (!this.announcement || !this.announcement.Type__c) {
            // fallback hvis announcement mangler
            return informationTemplate;
        }

        switch (this.announcement.Type__c) {
            case 'Information':
                return informationTemplate;
            case 'Warning':
                return warningTemplate;
            default:
                return informationTemplate; // fallback
        }
    }
}
