import { LightningElement, api } from 'lwc';
import informationTemplate from './information.html';
import warningTemplate from './warning.html';
import newsTemplate from './news.html';

import ICON_ExclamationmarkWhite from '@salesforce/resourceUrl/ExclamationmarkWhite';
import ICON_Exclamationmark from '@salesforce/resourceUrl/Exclamationmark';
import ICON_ExclamationmarkTriangleWhite from '@salesforce/resourceUrl/ExclamationmarkTriangleWhite';
import ICON_ChevronUpWhite from '@salesforce/resourceUrl/ChevronUpWhite';
import ICON_ChevronDownWhite from '@salesforce/resourceUrl/ChevronDownWhite';
import ICON_ChevronUp from '@salesforce/resourceUrl/ChevronUp';
import ICON_ChevronDown from '@salesforce/resourceUrl/ChevronDown';

export default class Hot_announcement extends LightningElement {
    // Ikoner
    ExclamationmarkIcon = ICON_Exclamationmark;
    ExclamationmarkWhiteIcon = ICON_ExclamationmarkWhite;
    ExclamationmarkTriangleWhiteIcon = ICON_ExclamationmarkTriangleWhite;
    ChevronUpWhiteIcon = ICON_ChevronUpWhite;
    ChevronDownWhiteIcon = ICON_ChevronDownWhite;
    ChevronUpIcon = ICON_ChevronUp;
    ChevronDownIcon = ICON_ChevronDown;

    @api announcement = null; // brukes for News
    @api announcements = []; // liste for Information/Warning
    @api type; // "Information" / "Warning" / "News"

    expanded = false;

    get title() {
        return this.announcement?.Title__c || '';
    }

    get description() {
        return this.announcement?.Description__c || '';
    }
    get url() {
        return this.announcement?.Url__c || '';
    }
    get urlLabel() {
        return this.announcement?.UrlLabel__c || '';
    }
    get createdDate() {
        if (!this.announcement?.CreatedDate) return '';
        const date = new Date(this.announcement.CreatedDate);

        // dd.mm.yyyy format
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();

        return `${day}.${month}.${year}`;
    }

    // ----- GRUPPERING LOGIKK -----
    get isSingle() {
        return this.announcements.length === 1;
    }

    get isGroup() {
        return this.announcements.length > 1;
    }

    get singleItem() {
        return this.isSingle ? this.announcements[0] : null;
    }

    // FINNER HEADER/TITTEL PÅ BOKS BASERT PÅ OM DET ER FLERE AV SAMME TYPE VARSLER SAMTIDIG ELLER IKKE
    get headerTitle() {
        if (this.isSingle) {
            return this.singleItem.Title__c;
        }

        return this.type === 'Information' || this.type === 'Warning' ? 'Viktig informasjon' : '';
    }

    get chevronIcon() {
        if (this.type === 'Warning') {
            return this.expanded ? this.ChevronUpIcon : this.ChevronDownIcon;
        }
        return this.expanded ? this.ChevronUpWhiteIcon : this.ChevronDownWhiteIcon;
    }

    toggleExpand() {
        this.expanded = !this.expanded;
    }

    handleKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.toggleExpand();
        }
    }

    // TEMPLATE
    render() {
        if (this.announcement?.Type__c === 'News') {
            return newsTemplate;
        }

        return this.type === 'Warning' ? warningTemplate : informationTemplate; // default
    }
}
