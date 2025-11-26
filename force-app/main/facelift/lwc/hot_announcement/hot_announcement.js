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
    // icons
    ExclamationmarkIcon = ICON_Exclamationmark;
    ExclamationmarkWhiteIcon = ICON_ExclamationmarkWhite;
    ExclamationmarkTriangleWhiteIcon = ICON_ExclamationmarkTriangleWhite;
    ChevronUpWhiteIcon = ICON_ChevronUpWhite;
    ChevronDownWhiteIcon = ICON_ChevronDownWhite;
    ChevronUpIcon = ICON_ChevronUp;
    ChevronDownIcon = ICON_ChevronDown;

    // props
    @api announcement = null; // brukes for News
    @api announcements = []; // liste for Information/Warning
    @api type; // "Information" / "Warning" / "News"

    expanded = false;

    // ----- NEWS MODE -----
    get title() {
        return this.announcement?.Title__c || '';
    }

    get description() {
        return this.announcement?.Description__c || '';
    }
    get createdDate() {
        return this.announcement?.CreatedDate || '';
    }

    // ----- GROUPING LOGIC -----
    get isGroup() {
        return this.announcements && this.announcements.length > 1;
    }

    get isSingle() {
        return this.announcements && this.announcements.length === 1;
    }

    get singleItem() {
        return this.isSingle ? this.announcements[0] : null;
    }

    // Header title for Information/Warning
    get headerTitle() {
        // NEWS → use original
        // if (this.announcement && this.announcement.Type__c === 'News') {
        //     return this.announcement.Title__c;
        // }

        // SINGLE Information/Warning → use actual title
        if (this.isSingle) {
            return this.singleItem.Title__c;
        }

        // MULTIPLE Information/Warning → use group title
        switch (this.type) {
            case 'Information':
                return 'Viktig informasjon';
            case 'Warning':
                return 'Viktig informasjon';
            default:
                return '';
        }
    }

    get chevronIcon() {
        if (this.type === 'Warning') {
            // bruk de ikke-hvite iconene
            return this.expanded ? this.ChevronUpIcon : this.ChevronDownIcon;
        }

        // default (Information + News)
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

    // TEMPLATE SELECTION
    render() {
        // NEWS behaves exactly as before
        if (this.announcement && this.announcement.Type__c === 'News') {
            return newsTemplate;
        }

        // GROUP INFO/WARNING
        if (this.type === 'Information') {
            return informationTemplate;
        }
        if (this.type === 'Warning') {
            return warningTemplate;
        }

        return informationTemplate;
    }
}
