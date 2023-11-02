public without sharing class HOT_MessagesNotification {
    public static void NotifyDispatcher(List<Id> threadIds) {
        List<Thread__c> threads = [
            SELECT Id, Name, OwnerId, HOT_Dispatcher__c, HOT_Subject__c
            FROM Thread__c
            WHERE Id IN :threadIds
        ];

        List<Id> ownerIds = new List<Id>();
        for (Thread__c thread : threads) {
            ownerIds.add(thread.OwnerId);
        }
        Map<Id, ID> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(ownerIds);

        for (Thread__c thread : threads) {
            Set<String> recipients = new Set<String>();
            if (thread.HOT_Dispatcher__c != null) {
                recipients.add(thread.HOT_Dispatcher__c);
            } else {
                recipients.add(groupByQueue.get(thread.OwnerId));
            }
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Ny melding');
            notification.setBody(thread.HOT_Subject__c); // send med parameter for denne
            notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyDispatcher').Id); // send med parameter for denne
            notification.setTargetId(thread.Id); // send med parameter for denne
            HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread); // send med parameter for denne
        }
    }

    public static void notifyUser(List<Id> threadIds) {
        List<Thread__c> threads = [
            SELECT
                CRM_Account__c,
                CRM_Thread_Type__c,
                HOT_Participants__c,
                HOT_IsEmployeeThread__c,
                CRM_Account__r.INT_KrrMobilePhone__c,
                CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c,
                CRM_Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c
            FROM Thread__c
            WHERE
                Id IN :threadIds
                AND CRM_Account__c != NULL
                AND CRM_Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE
        ];
        List<Id> accountIds = new List<Id>();

        for (Thread__c thread : threads) {
            accountIds.add(thread.CRM_Account__c);
        }

        List<User> users = [
            SELECT Id, AccountId, (SELECT Id, HOT_NotificationChannel__c FROM ServiceResources)
            FROM User
            WHERE AccountId IN :accountIds
        ];
        Map<Id, ServiceResource> userToServiceResource = new Map<Id, ServiceResource>();
        for (User user : users) {
            if (user.ServiceResources.size() > 0) {
                userToServiceResource.put(user.Id, user.ServiceResources[0]);
            }
        }

        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        if (!threads.isEmpty()) {
            for (Thread__c thread : threads) {
                Boolean isInterpreter = (thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                    (thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' && !thread.HOT_IsEmployeeThread__c))
                    ? true
                    : false;
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(thread.CRM_Account__c) != null) {
                    recipients.add(userIdByAccountId.get(thread.CRM_Account__c));
                }
                if (recipients.size() > 0) {
                    if (
                        (thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' &&
                        userToServiceResource.get(userIdByAccountId.get(thread.CRM_Account__c))
                            .HOT_NotificationChannel__c.contains('Push')) ||
                        thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')
                    ) {
                        if (
                            thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                            thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER'
                        ) {
                            //creating notification object
                            HOT_Notification__c notification = new HOT_Notification__c();
                            notification.HOT_Account__c = thread.CRM_Account__c;
                            notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                            notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                            notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
                            notification.HOT_RelatedObject__c = thread.Id;
                            notification.HOT_RelatedObjectType__c = 'threadInterpreter';

                            notificationList.add(notification);
                        } else {
                            //creating notification object
                            HOT_Notification__c notification = new HOT_Notification__c();
                            notification.HOT_Account__c = thread.CRM_Account__c;
                            notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                            notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                            notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
                            notification.HOT_RelatedObject__c = thread.Id;
                            notification.HOT_RelatedObjectType__c = 'threadUser';

                            notificationList.add(notification);
                        }

                        HOT_UserNotificationService.newMessageNotification(
                            getCustomNotificationType('HOT_NotifyUser'),
                            thread,
                            isInterpreter,
                            recipients
                        );
                    } else {
                        Set<Id> threadList = new Set<Id>();
                        threadList.add(thread.Id);
                        if (
                            thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                            thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER'
                        ) {
                            //creating notification object
                            HOT_Notification__c notification = new HOT_Notification__c();
                            notification.HOT_Account__c = thread.CRM_Account__c;
                            notification.HOT_NotificationChannel__c = 'SMS';
                            notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                            notification.HOT_NotificationText__c =
                                'INFO Du har fått en melding fra tolketjenesten.\nFor mer informasjon, se tolkebestilling.nav.no.\n' +
                                'Du kan ikke svare på denne meldingen.\n' +
                                'Mvh tolketjenesten i NAV';
                            notification.HOT_RelatedObject__c = thread.Id;
                            notification.HOT_RelatedObjectType__c = 'threadInterpreter';

                            notificationList.add(notification);
                        } else {
                            //creating notification object
                            HOT_Notification__c notification = new HOT_Notification__c();
                            notification.HOT_Account__c = thread.CRM_Account__c;
                            notification.HOT_NotificationChannel__c = 'SMS';
                            notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                            notification.HOT_NotificationText__c =
                                'INFO Du har fått en melding fra tolketjenesten.\nFor mer informasjon, se tolkebestilling.nav.no.\n' +
                                'Du kan ikke svare på denne meldingen.\n' +
                                'Mvh tolketjenesten i NAV';
                            notification.HOT_RelatedObject__c = thread.Id;
                            notification.HOT_RelatedObjectType__c = 'threadUser';

                            notificationList.add(notification);
                        }

                        HOT_ReminderSMSService.sendSMSOnNewMessage(threadList);
                    }
                }
            }
            //inserting notifications
            try {
                HOT_NotificationCentreController.createNotification(notificationList);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        }
    }
    @Future
    public static void NotifyInterpreter(List<Id> threadIds) {
        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_Participants__c,
                HOT_Last_message_from__c,
                HOT_Last_message_from__r.AccountId,
                HOT_Subject__c,
                CRM_Thread_Type__c,
                LastModifiedById
            FROM Thread__c
            WHERE Id IN :threadIds
        ];

        Set<Id> participantIdsSet = new Set<Id>();
        if (!threads.isEmpty()) {
            Map<Id, Thread__c> interpretersOnThreadMap = new Map<Id, Thread__c>();

            for (Thread__c t : threads) {
                String[] participantIds = t.HOT_Participants__c.split(', ');

                for (String participantId : participantIds) {
                    participantId = participantId.trim();

                    if (participantId != '') {
                        interpretersOnThreadMap.put(participantId, t);
                        participantIdsSet.add(participantId);
                    }
                }
            }
            List<ServiceResource> employeeServiceresource = [
                SELECT Id, RelatedRecordId, HOT_NotificationChannel__c
                FROM ServiceResource
                WHERE RelatedRecordId IN :participantIdsSet AND HOT_IsEmployedInterpreter__c = TRUE
            ];
            List<ServiceResource> freelanceServiceresource = [
                SELECT Id, AccountId, HOT_NotificationChannel__c
                FROM ServiceResource
                WHERE RelatedRecordId IN :participantIdsSet AND HOT_IsFreelanceInterpreter__c = TRUE
            ];

            //ANSATTOLKER VARSEL
            if (!employeeServiceresource.isEmpty()) {
                Set<Id> employeeUserIds = new Set<Id>();
                for (ServiceResource sr : employeeServiceresource) {
                    employeeUserIds.add(sr.RelatedRecordId);
                }

                List<User> users = [
                    SELECT Id, AccountId, (SELECT Id, HOT_NotificationChannel__c FROM ServiceResources)
                    FROM User
                    WHERE Id IN :employeeUserIds
                ];

                Map<User, Thread__c> userIdToThreadMap = new Map<User, Thread__c>();
                for (Id participantId : interpretersOnThreadMap.keySet()) {
                    Thread__c threadId = interpretersOnThreadMap.get(participantId);
                    for (User user : users) {
                        if (participantId == user.Id && threadId.LastModifiedById != user.Id) {
                            userIdToThreadMap.put(User, threadId);
                        }
                    }
                }
                for (User user : userIdToThreadMap.keySet()) {
                    String notificationChannel = user.ServiceResources[0].HOT_NotificationChannel__c;
                    Thread__c thread = userIdToThreadMap.get(user);
                    if (notificationChannel.contains('Push')) {
                        Set<String> recipients = new Set<String>();
                        recipients.add(user.Id);
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('Ny melding');
                        notification.setBody(thread.HOT_Subject__c); // send med parameter for denne
                        notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyInterpreter').Id); // send med parameter for denne
                        notification.setTargetId(thread.Id); // send med parameter for denne
                        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread); // send med parameter for denne
                    } else {
                        Set<Id> threadList = new Set<Id>();
                        threadList.add(thread.Id);
                        HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(user.Id, thread.Id);
                    }
                }
            }

            //FRILANSTOLKER VARSEL
            if (!freelanceServiceresource.isEmpty()) {
                Set<Id> freelanceAccountIds = new Set<Id>();
                for (ServiceResource sr : freelanceServiceresource) {
                    freelanceAccountIds.add(sr.AccountId);
                }

                List<User> users = [
                    SELECT Id, AccountId, (SELECT Id, HOT_NotificationChannel__c FROM ServiceResources)
                    FROM User
                    WHERE AccountId IN :freelanceAccountIds
                ];

                Map<User, Thread__c> userIdToThreadMap = new Map<User, Thread__c>();
                for (Id participantId : interpretersOnThreadMap.keySet()) {
                    Thread__c threadId = interpretersOnThreadMap.get(participantId);
                    for (User user : users) {
                        if (participantId == user.Id) {
                            userIdToThreadMap.put(User, threadId);
                        }
                    }
                }
                //creating notification object list
                List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

                for (User user : userIdToThreadMap.keySet()) {
                    Set<String> recipients = new Set<String>();
                    String notificationChannel = user.ServiceResources[0].HOT_NotificationChannel__c;
                    Thread__c thread = userIdToThreadMap.get(user);
                    if (thread.HOT_Last_message_from__r.AccountId != user.AccountId) {
                        recipients.add(user.Id);
                    }

                    if (recipients.size() > 0) {
                        if (notificationChannel.contains('Push')) {
                            //creating notification object
                            HOT_Notification__c notification = new HOT_Notification__c();
                            notification.HOT_Account__c = user.AccountId;
                            notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                            notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                            notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
                            notification.HOT_RelatedObject__c = thread.Id;
                            notification.HOT_RelatedObjectType__c = 'threadInterpreter';

                            notificationList.add(notification);
                            HOT_UserNotificationService.newMessageNotification(
                                getCustomNotificationType('HOT_NotifyUser'),
                                thread,
                                true,
                                recipients
                            );
                        } else {
                            Set<Id> threadList = new Set<Id>();
                            threadList.add(thread.Id);
                            //creating notification object
                            HOT_Notification__c notification = new HOT_Notification__c();
                            notification.HOT_Account__c = user.AccountId;
                            notification.HOT_NotificationChannel__c = 'SMS';
                            notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                            notification.HOT_NotificationText__c =
                                'INFO Du har fått en melding fra tolketjenesten. \nFor mer informasjon, se tolkebestilling.nav.no.\n' +
                                'Du kan ikke svare på denne meldingen.\n' +
                                'Mvh tolketjenesten i NAV';
                            notification.HOT_RelatedObject__c = thread.Id;
                            notification.HOT_RelatedObjectType__c = 'threadInterpreter';

                            notificationList.add(notification);
                            HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(user.Id, thread.Id);
                        }
                    }
                }
                //inserting notifications
                try {
                    HOT_NotificationCentreController.createNotification(notificationList);
                } catch (Exception e) {
                    LoggerUtility logger = new LoggerUtility();
                    logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                    logger.publish();
                }
            }
        }
    }

    public static CustomNotificationType getCustomNotificationType(String devName) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = :devName
        ];
        return notificationType;
    }
}
