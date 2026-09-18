import { LightningElement, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/User.LastName';
import icons from '@salesforce/resourceUrl/aksel_ikoner';
import getmyNotifications from '@salesforce/apex/HOT_TLNotificationController.getMyNotifications';
import markAllNotificationsAsRead from '@salesforce/apex/HOT_TLNotificationController.markAllNotificationsAsRead';
import { formatDatetime } from 'c/datetimeFormatterNorwegianTime';

const USER_FIELDS = [FIRST_NAME_FIELD, LAST_NAME_FIELD];

export default class Hot_tlLoginBanner extends LightningElement {
    LeaveIcon = icons + '/Law_and_security/Leave.svg';
    PeopleIcon = icons + '/People/Person.svg';
    ChevronUpIcon = icons + '/Arrows/ChevronUp.svg';
    ChevronDownIcon = icons + '/Arrows/ChevronDown.svg';
    MenuIcon = icons + '/Interface/MenuHamburger.svg';

    notifications = [];

    @wire(getmyNotifications)
    wiredNotifications({ error, data }) {
        if (data) {
            this.notifications = data.map((notification) => ({
                id: notification.Id,
                title: notification.HOT_Subject__c,
                text: notification.HOT_NotificationText__c,
                relatedObjectId: notification.HOT_RelatedObject__c,
                relatedObjectType: notification.HOT_RelatedObjectType__c,
                createdDate: formatDatetime(notification.CreatedDate),
                isRead: notification.HOT_IsRead__c
            }));
        } else if (error) {
            console.error('Error fetching notifications:', error);
        }
    }

    markAllAsRead() {
        markAllNotificationsAsRead()
            .then(() => {
                this.notifications = this.notifications.map((notification) => ({
                    ...notification,
                    isRead: true
                }));
            })
            .catch((error) => {
                console.error('Error marking all notifications as read:', error);
            });
    }

    // Lenker som vises på venstre side
    navLinks = [
        {
            id: '1',
            label: 'Oppdrag',
            url: '#'
        },
        {
            id: '2',
            label: 'Ressursplanlegger',
            url: '#'
        },
        {
            id: '4',
            label: 'Samtaler',
            url: '#'
        }
    ];

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    userRecord;

    get userName() {
        const firstName = getFieldValue(this.userRecord.data, FIRST_NAME_FIELD) || '';
        const lastName = getFieldValue(this.userRecord.data, LAST_NAME_FIELD) || '';
        const fullName = `${firstName} ${lastName}`.trim();
        return fullName || 'Bruker';
    }

    get unreadCount() {
        return this.notifications.filter((notification) => !notification.isRead).length;
    }

    get hasNotifications() {
        return this.notifications.length > 0;
    }

    get hasUnreadNotifications() {
        return this.notifications.some((notification) => !notification.isRead);
    }

    isDropdownOpen = false;
    isNotificationDropdownOpen = false;
    isNavDropdownOpen = false;
    hasRegisteredDocumentClick = false;
    handleDocumentClickBound;

    connectedCallback() {
        this.handleDocumentClickBound = this.handleDocumentClick.bind(this);
    }

    renderedCallback() {
        if (!this.hasRegisteredDocumentClick) {
            document.addEventListener('click', this.handleDocumentClickBound);
            this.hasRegisteredDocumentClick = true;
        }
    }

    disconnectedCallback() {
        if (this.hasRegisteredDocumentClick) {
            document.removeEventListener('click', this.handleDocumentClickBound);
            this.hasRegisteredDocumentClick = false;
        }
    }

    get dropdownClass() {
        return this.isDropdownOpen ? 'dropdown-menu dropdown-open' : 'dropdown-menu';
    }

    get notificationDropdownClass() {
        return this.isNotificationDropdownOpen
            ? 'dropdown-menu notification-dropdown dropdown-open'
            : 'dropdown-menu notification-dropdown';
    }

    get navDropdownClass() {
        return this.isNavDropdownOpen ? 'dropdown-menu nav-dropdown dropdown-open' : 'dropdown-menu nav-dropdown';
    }

    closeAllDropdowns() {
        this.isDropdownOpen = false;
        this.isNotificationDropdownOpen = false;
        this.isNavDropdownOpen = false;
    }

    handleDocumentClick(event) {
        const clickPath = event.composedPath ? event.composedPath() : [];
        const clickedInsideComponent = clickPath.includes(this.template.host) || this.template.contains(event.target);
        if (!clickedInsideComponent) {
            this.closeAllDropdowns();
        }
    }

    toggleNavDropdown() {
        this.isDropdownOpen = false;
        this.isNotificationDropdownOpen = false;
        this.isNavDropdownOpen = !this.isNavDropdownOpen;
    }

    toggleDropdown() {
        this.isNavDropdownOpen = false;
        this.isNotificationDropdownOpen = false;
        this.isDropdownOpen = !this.isDropdownOpen;
    }

    toggleNotificationDropdown() {
        if (!this.isNotificationDropdownOpen && this.hasUnreadNotifications) {
            this.markAllAsRead();
        }
        this.isNavDropdownOpen = false;
        this.isDropdownOpen = false;
        this.isNotificationDropdownOpen = !this.isNotificationDropdownOpen;
    }

    handleLogout() {
        console.log('Logger ut');
    }
}
