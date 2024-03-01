import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyNotifications from '@salesforce/apex/HOT_NotificationCentreController.getMyNotifications';
import getNotificationType from '@salesforce/apex/HOT_NotificationCentreController.getNotificationType';
import checkThreadAccess from '@salesforce/apex/HOT_NotificationCentreController.checkThreadAccess';
import getTargetPage from '@salesforce/apex/HOT_NotificationCentreController.getTargetPage';

import { refreshApex } from '@salesforce/apex';
export default class Hot_notificationList extends NavigationMixin(LightningElement) {
    @track isMobile;
    @track errorMessage;
    @track columns = [];
    showMyNotifications = true;
    noNotifications;
    setTable() {
        if (window.screen.width > 576) {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }
    }
    breadcrumbs = [
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Mine varsler',
            href: 'mine-varsler'
        }
    ];
    @track unmappedNotifications;
    @track notifications;

    connectedCallback() {
        this.setTable();
        refreshApex(this.wiredNotificationResult);
    }

    wiredNotificationResult;
    @wire(getMyNotifications)
    wiredNotifications(result) {
        this.wiredNotificationResult = result;
        if (result.data) {
            this.unmappedNotifications = [];
            this.notifications = [];
            result.data.forEach((element) => {
                this.unmappedNotifications.push(element);
            });
            if (this.unmappedNotifications.length == 0) {
                this.noNotifications = true;
            }

            this.notifications = this.unmappedNotifications.map((x) => ({
                ...x,
                created: this.formatDateTime(x.CreatedDate)
            }));
            this.notifications.sort((a, b) => {
                if (b.CreatedDate === a.CreatedDate) {
                    return 0;
                } else {
                    return b.CreatedDate < a.CreatedDate ? -1 : 1;
                }
            });
        }
    }
    goToNotification(event) {
        const clickedButton = event.target;
        const notificationElement = clickedButton.closest('[data-id]');

        if (notificationElement) {
            const notificationId = notificationElement.getAttribute('data-id');
            getNotificationType({ notificationId: notificationId })
                .then((result) => {
                    if (result.HOT_RelatedObjectType__c == 'wanted') {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-oppdrag'
                            },
                            state: { list: 'wanted', from: 'mine-varsler' }
                        });
                    }
                    if (result.HOT_RelatedObjectType__c == 'serviceAppointment') {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-oppdrag'
                            },
                            state: { list: 'my', from: 'mine-varsler', id: result.HOT_RelatedObject__c }
                        });
                    }
                    if (result.HOT_RelatedObjectType__c == 'noServiceAppointment') {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-oppdrag'
                            },
                            state: { list: 'interested', from: 'mine-varsler', id: result.HOT_RelatedObject__c }
                        });
                    }
                    if (result.HOT_RelatedObjectType__c == 'workOrder') {
                        var relatedId = result.HOT_RelatedObject__c;
                        getTargetPage({ workOrderId: result.HOT_RelatedObject__c }).then((result) => {
                            if (result == 'mine-bestillinger-andre') {
                                this[NavigationMixin.Navigate]({
                                    type: 'comm__namedPage',
                                    attributes: {
                                        pageName: 'mine-bestillinger-andre'
                                    },
                                    state: {
                                        id: relatedId,
                                        level: 'WO',
                                        from: 'mine-varsler'
                                    }
                                });
                            } else {
                                this[NavigationMixin.Navigate]({
                                    type: 'comm__namedPage',
                                    attributes: {
                                        pageName: 'mine-bestillinger'
                                    },
                                    state: {
                                        id: relatedId,
                                        level: 'WO',
                                        from: 'mine-varsler'
                                    }
                                });
                            }
                        });
                    }
                    if (result.HOT_RelatedObjectType__c == 'request') {
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
                    }
                    if (result.HOT_RelatedObjectType__c == 'threadUser') {
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
                    }
                    if (result.HOT_RelatedObjectType__c == 'threadInterpreter') {
                        let threadId = result.HOT_RelatedObject__c;
                        checkThreadAccess({ threadId: threadId }).then((result) => {
                            if (result == false) {
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
                        });
                    }
                })
                .catch((error) => {});
        }
    }
    closeModal() {
        this.template.querySelector('.notificationDetails').classList.add('hidden');
        this.recordId = undefined;
        this.updateURL();
        this.isGoToThreadButtonDisabled = false;
        this.isGoToThreadServiceAppointmentButtonDisabled = false;
        this.isGoToThreadInterpretersButtonDisabled = false;
    }
    goBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
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
