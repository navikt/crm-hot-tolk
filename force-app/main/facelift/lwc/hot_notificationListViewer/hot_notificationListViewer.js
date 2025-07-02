import { LightningElement, track, wire } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';
import { NavigationMixin } from 'lightning/navigation';
import getMyNotifications from '@salesforce/apex/HOT_NotificationCentreController.getMyNotifications';
import getNotificationType from '@salesforce/apex/HOT_NotificationCentreController.getNotificationType';
import checkAccess from '@salesforce/apex/HOT_ThreadDetailController.checkAccess';
import getTargetPage from '@salesforce/apex/HOT_NotificationCentreController.getTargetPage';

export default class Hot_notificationListViewer extends NavigationMixin(LightningElement) {
    notificationIcon = icons + '/Bell/Bell.svg';
    exitCrossIcon = icons + '/Close/Close.svg';
    showNotifications = false;
    @track notifications;

    @wire(getMyNotifications)
    wiredNotifications(result) {
        this.wiredNotificationResult = result;
        if (result.data) {
            const notifications = result.data.map((x) => ({
                ...x,
                created: this.formatDateTime(x.CreatedDate),
                ariaLabel: `Åpne varsel: ${x.HOT_Subject__c}. ${x.HOT_NotificationText__c}`
            }));

            // Sort by CreatedDate descending
            notifications.sort((a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate));

            this.notifications = notifications;
            console.log(this.notifications);
        }
    }

    get hasNotifications() {
        return this.notifications && this.notifications.length > 0;
    }
    /* toggleNotifications() {
        this.showNotifications = !this.showNotifications;
        this.template.querySelector('.dropdown').focus();
    } */

    async goToNotification(event) {
        console.log('knapp trykket');
        //const clickedButton = event.target;
        //const notificationElement = clickedButton.closest('[data-id]');
        const notificationElement = event.currentTarget;
        console.log('notificationElement:', notificationElement);
        console.log('dataset:', notificationElement.dataset);
        console.log('data-id attribute:', notificationElement.getAttribute('data-id'));

        if (notificationElement) {
            const notificationId = notificationElement.getAttribute('data-id');
            console.log('notficationId', notificationId);

            try {
                const result = await getNotificationType({ notificationId: notificationId });
                console.log('result.HOT_relatedobject', result.HOT_RelatedObjectType__c);
                switch (result.HOT_RelatedObjectType__c) {
                    case 'wanted': {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-oppdrag'
                            },
                            state: { list: 'wanted', from: 'mine-varsler' }
                        });
                        break;
                    }
                    case 'serviceAppointment': {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-oppdrag'
                            },
                            state: { list: 'my', from: 'mine-varsler', id: result.HOT_RelatedObject__c }
                        });
                        break;
                    }
                    case 'noServiceAppointment': {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-oppdrag'
                            },
                            state: { list: 'interested', from: 'mine-varsler', id: result.HOT_RelatedObject__c }
                        });
                        break;
                    }
                    case 'workOrder': {
                        var relatedId = result.HOT_RelatedObject__c;
                        const targetPage = await getTargetPage({ workOrderId: relatedId });
                        if (targetPage == 'mine-bestillinger-andre') {
                            this[NavigationMixin.Navigate]({
                                type: 'comm__namedPage',
                                attributes: { pageName: 'mine-bestillinger-andre' },
                                state: { id: relatedId, level: 'WO', from: 'mine-varsler' }
                            });
                        } else {
                            this[NavigationMixin.Navigate]({
                                type: 'comm__namedPage',
                                attributes: { pageName: 'mine-bestillinger' },
                                state: { id: relatedId, level: 'WO', from: 'mine-varsler' }
                            });
                        }
                        break;
                    }

                    case 'request': {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-bestillinger'
                            },
                            state: {
                                id: result.HOT_RelatedObject__c,
                                level: 'R',
                                from: 'mine-varsler'
                            }
                        });
                        break;
                    }
                    case 'threadUser': {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result.HOT_RelatedObject__c,
                                objectApiName: 'Thread__c',
                                actionName: 'view'
                            },
                            state: {
                                from: 'mine-varsler-tolkebruker'
                            }
                        });
                        break;
                    }
                    case 'threadInterpreter': {
                        let threadId = result.HOT_RelatedObject__c;
                        const access = await checkAccess({ threadId: threadId });
                        if (access) {
                            const baseUrl = '/samtale-frilans';
                            const attributes = `recordId=${threadId}&from=mine-varsler`;
                            const url = `${baseUrl}?${attributes}`;

                            this[NavigationMixin.Navigate]({
                                type: 'standard__webPage',
                                attributes: {
                                    url: url
                                }
                            });
                        } else {
                            this.errorMessage =
                                'Du trykket på et gammelt varsel til et oppdrag du ikke lenger er tildelt.';
                            this.template.querySelector('.notificationDetails').classList.remove('hidden');
                            this.template.querySelector('.notificationDetails').focus();
                        }
                        break;
                    }
                    default:
                        break;
                }
            } catch (error) {
                console.error(error);
            }
        }
    }

    toggleNotifications() {
        this.showNotifications = !this.showNotifications;
        if (this.showNotifications) {
            // after DOM updates, focus first tabbable in dropdown
            setTimeout(() => {
                const first = this._getTrapElements()[0]; //First notification
                first && first.focus();
            });
        }
    }

    handleFocusTrap(e) {
        if (e.key !== 'Tab') return;
        const focusables = this._getTrapElements();
        const first = focusables[0];
        const last = focusables[focusables.length - 1];
        const active = this.template.activeElement;

        if (!e.shiftKey && active === last) {
            e.preventDefault();
            first.focus();
        }
        if (e.shiftKey && active === first) {
            e.preventDefault();
            last.focus();
        }
    }

    _getTrapElements() {
        const dropdown = this.template.querySelector('.dropdown');
        if (!dropdown) return [];
        return Array.from(
            dropdown.querySelectorAll(
                `a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])`
            )
        );
    }

    formatDateTime(date) {
        let unformatted = new Date(date);
        let formattedTime =
            ('0' + unformatted.getDate()).slice(-2) +
            '.' +
            ('0' + (unformatted.getMonth() + 1)).slice(-2) +
            '.' +
            unformatted.getFullYear() +
            ', Kl ' +
            ('0' + unformatted.getHours()).slice(-2) +
            ':' +
            ('0' + unformatted.getMinutes()).slice(-2);
        if (formattedTime.includes('NaN')) {
            formattedTime = '';
        }
        return formattedTime;
    }
}
