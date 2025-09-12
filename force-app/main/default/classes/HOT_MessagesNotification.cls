public without sharing class HOT_MessagesNotification {
    public static HOT_Notification__c newMessageNotificationPush(Id accountId, Thread__c thread, String type) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_Account__c = accountId;
        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
        notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
        notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
        notification.HOT_RelatedObject__c = thread.Id;
        notification.HOT_RelatedObjectType__c = type;
        return notification;
    }
    public static HOT_Notification__c newMessageNotificationSMS(Id accountId, Thread__c thread, String type) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_Account__c = accountId;
        notification.HOT_NotificationChannel__c = 'SMS';
        notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
        notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
        notification.HOT_RelatedObject__c = thread.Id;
        notification.HOT_RelatedObjectType__c = type;
        return notification;
    }
    private static void insertNotifications(List<HOT_Notification__c> notifications) {
        try {
            HOT_NotificationCentreController.createNotification(notifications);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }
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
            notification.setBody(thread.HOT_Subject__c);
            notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyDispatcher').Id);
            notification.setTargetId(thread.Id);
            HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread);
        }
    }

    public static void notifyUser(List<Id> threadIds) {
        List<Thread__c> threads = [
            SELECT
                CRM_Account__c,
                CRM_Thread_Type__c,
                HOT_ParticipantIds__c,
                HOT_IsEmployeeThread__c,
                LastModifiedById,
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
        //LAGER VARSLINGS LISTE TIL INSETTING SENERE
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        if (!threads.isEmpty()) {
            for (Thread__c thread : threads) {
                Boolean isInterpreter = (thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                    (thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' && !thread.HOT_IsEmployeeThread__c))
                    ? true
                    : false;
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(thread.CRM_Account__c) != null) {
                    if (userIdByAccountId.get(thread.CRM_Account__c) != thread.LastModifiedById) {
                        recipients.add(userIdByAccountId.get(thread.CRM_Account__c));
                    }
                }
                if (recipients.size() > 0) {
                    //FØRST MÅ MAN FINNE UT AV OM DET ER EN TOLKE SAMTALE ELLER EN SAMTALE SOM BRUKER, OG BASERT PÅ DET BRUKE BRUKEREN  ELLER TOLKEN SIN VARSLINGSMETODE
                    if (
                        (thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' &&
                        userToServiceResource.get(userIdByAccountId.get(thread.CRM_Account__c))
                            ?.HOT_NotificationChannel__c.contains('Push')) ||
                        (thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' &&
                        thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) ||
                        (thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' &&
                        thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) ||
                        (thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK' &&
                        thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) ||
                        (thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER' &&
                        thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push'))
                    ) {
                        if (
                            thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                            thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER'
                        ) {
                            //BETYR AT VARSELET SKAL LINKE TIL TOLKE SAMTALER. SAMTALER MELLOM RESSURSKONTOR OG EN TIL EN MED FORMIDLER
                            //LAGER NOTIFIKASJON
                            HOT_Notification__c newNotification = newMessageNotificationPush(
                                thread.CRM_Account__c,
                                thread,
                                'threadInterpreter'
                            );
                            notificationList.add(newNotification);
                        } else {
                            //BETYR AT VARSELET SKAL LINKE TIL SAMTALE HVOR BRUKEREN IKKE ER TOLK
                            //LAGER NOTIFIKASJON
                            HOT_Notification__c newNotification = newMessageNotificationPush(
                                thread.CRM_Account__c,
                                thread,
                                'threadUser'
                            );
                            notificationList.add(newNotification);
                        }
                        //SENDER UT PUSHVARSEL TIL MOBIL
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
                            //BETYR AT VARSELET SKAL LINKE TIL TOLKE SAMTALER. SAMTALER MELLOM RESSURSKONTOR OG EN TIL EN MED FORMIDLER
                            //LAGER NOTIFIKASJONSOBJEKTET
                            HOT_Notification__c newNotification = newMessageNotificationSMS(
                                thread.CRM_Account__c,
                                thread,
                                'threadInterpreter'
                            );
                            notificationList.add(newNotification);
                        } else {
                            //BETYR AT VARSELET SKAL LINKE TIL SAMTALE HVOR BRUKEREN IKKE ER TOLK
                            //LAGER NOTIFIKASJONSOBJEKTET
                            HOT_Notification__c newNotification = newMessageNotificationSMS(
                                thread.CRM_Account__c,
                                thread,
                                'threadUser'
                            );
                            notificationList.add(newNotification);
                        }
                        //SENDER SMS
                        HOT_ReminderSMSService.sendSMSOnNewMessage(threadList);
                    }
                }
            }
            //INSERTE NOTIFIKASJONSRECORD TIL VARSLINGSSENTERET
            insertNotifications(notificationList);
        }
    }
    public static void NotifyInterpreter(List<Id> threadIds) {
        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_ParticipantIds__c,
                HOT_IsEmployeeThread__c,
                HOT_Subject__c,
                CRM_Thread_Type__c,
                LastModifiedById
            FROM Thread__c
            WHERE Id IN :threadIds
        ];

        if (!threads.isEmpty()) {
            Map<Id, List<Thread__c>> interpretersOnThreadMap = new Map<Id, List<Thread__c>>();

            for (Thread__c t : threads) {
                String[] participantIds = t.HOT_ParticipantIds__c.split(',');

                for (String participantId : participantIds) {
                    participantId = participantId.trim();

                    if (participantId == '') {
                        continue;
                    }
                    if (interpretersOnThreadMap.containsKey(participantId)) {
                        interpretersOnThreadMap.get(participantId).add(t);
                    } else {
                        interpretersOnThreadMap.put(participantId, new List<Thread__c>{ t });
                    }
                }
            }
            List<ServiceResource> employeeServiceresource = [
                SELECT Id, RelatedRecordId, HOT_NotificationChannel__c
                FROM ServiceResource
                WHERE RelatedRecordId IN :interpretersOnThreadMap.keySet() AND HOT_IsEmployedInterpreter__c = TRUE
            ];
            List<ServiceResource> freelanceServiceresource = [
                SELECT Id, AccountId, HOT_NotificationChannel__c
                FROM ServiceResource
                WHERE RelatedRecordId IN :interpretersOnThreadMap.keySet() AND HOT_IsFreelanceInterpreter__c = TRUE
            ];
            //LAGER VARSLINGS LISTE TIL INSETTING SENERE
            List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
            //ANSATTOLKER VARSEL
            if (!employeeServiceresource.isEmpty()) {
                Set<Id> employeeUserIds = new Set<Id>();
                for (ServiceResource sr : employeeServiceresource) {
                    employeeUserIds.add(sr.RelatedRecordId);
                }

                Map<Id, User> userMap = new Map<Id, User>(
                    [
                        SELECT Id, AccountId, (SELECT Id, HOT_NotificationChannel__c FROM ServiceResources)
                        FROM User
                        WHERE Id IN :employeeUserIds
                    ]
                );

                Map<User, List<Thread__c>> userIdToThreadMap = new Map<User, List<Thread__c>>();
                for (Id participantId : interpretersOnThreadMap.keySet()) {
                    if (!userMap.containsKey(participantId)) {
                        continue;
                    }
                    for (Thread__c thread : interpretersOnThreadMap.get(participantId)) {
                        if (thread.LastModifiedById == participantId) {
                            continue;
                        }
                        if (userIdToThreadMap.containsKey(userMap.get(participantId))) {
                            userIdToThreadMap.get(userMap.get(participantId)).add(thread);
                        } else {
                            userIdToThreadMap.put(userMap.get(participantId), new List<Thread__c>{ thread });
                        }
                    }
                }
                Map<User, List<Thread__c>> userIdToThreadMapSMS = new Map<User, List<Thread__c>>();
                for (User user : userIdToThreadMap.keySet()) {
                    if (user.ServiceResources[0].HOT_NotificationChannel__c.contains('Push')) {
                        for (Thread__c thread : userIdToThreadMap.get(user)) {
                            Set<String> recipients = new Set<String>();
                            recipients.add(user.Id);
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            notification.setTitle('Ny melding');
                            notification.setBody(thread.HOT_Subject__c);
                            notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyInterpreter').Id);
                            notification.setTargetId(thread.Id);
                            HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread);

                            if (!user.ServiceResources.isEmpty()) {
                                HOT_Notification__c newNotification = new HOT_Notification__c();
                                newNotification.HOT_ServiceResource__c = user.ServiceResources[0].Id; // Fetch ServiceResource ID
                                newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                                newNotification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                                newNotification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
                                newNotification.HOT_RelatedObject__c = thread.Id;
                                newNotification.HOT_RelatedObjectType__c = 'threadInterpreter';
                                notificationList.add(newNotification);
                            }
                        }
                    } else {
                        userIdToThreadMapSMS.put(user, userIdToThreadMap.get(user));
                    }
                }
                //SENDER SMS
                if (!userIdToThreadMapSMS.isEmpty()) {
                    HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(userIdToThreadMapSMS);
                }
            }

            //FRILANSTOLKER VARSEL
            if (!freelanceServiceresource.isEmpty()) {
                Set<Id> freelanceAccountIds = new Set<Id>();

                for (ServiceResource sr : freelanceServiceresource) {
                    freelanceAccountIds.add(sr.AccountId);
                }
                Map<Id, User> userMap = new Map<Id, User>(
                    [
                        SELECT Id, AccountId, (SELECT Id, HOT_NotificationChannel__c FROM ServiceResources)
                        FROM User
                        WHERE AccountId IN :freelanceAccountIds
                    ]
                );

                Map<User, List<Thread__c>> userIdToThreadMap = new Map<User, List<Thread__c>>();
                for (Id participantId : interpretersOnThreadMap.keySet()) {
                    if (!userMap.containsKey(participantId)) {
                        continue;
                    }
                    for (Thread__c thread : interpretersOnThreadMap.get(participantId)) {
                        if (thread.LastModifiedById == participantId) {
                            continue;
                        }
                        if (userIdToThreadMap.containsKey(userMap.get(participantId))) {
                            userIdToThreadMap.get(userMap.get(participantId)).add(thread);
                        } else {
                            userIdToThreadMap.put(userMap.get(participantId), new List<Thread__c>{ thread });
                        }
                    }
                }
                Map<User, List<Thread__c>> userIdToThreadMapSMS = new Map<User, List<Thread__c>>();
                for (User user : userIdToThreadMap.keySet()) {
                    if (user.ServiceResources[0].HOT_NotificationChannel__c.contains('Push')) {
                        for (Thread__c thread : userIdToThreadMap.get(user)) {
                            if (!user.ServiceResources.isEmpty()) {
                                HOT_Notification__c newNotification = new HOT_Notification__c();
                                newNotification.HOT_ServiceResource__c = user.ServiceResources[0].Id; // Fetch ServiceResource ID
                                newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                                newNotification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                                newNotification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
                                newNotification.HOT_RelatedObject__c = thread.Id;
                                newNotification.HOT_RelatedObjectType__c = 'threadInterpreter';
                                notificationList.add(newNotification);
                            }
                            HOT_UserNotificationService.newMessageNotification(
                                getCustomNotificationType('HOT_NotifyUser'),
                                thread,
                                true,
                                new Set<String>{ user.Id }
                            );
                        }
                    } else {
                        for (Thread__c thread : userIdToThreadMap.get(user)) {
                            if (!user.ServiceResources.isEmpty()) {
                                HOT_Notification__c newNotification = new HOT_Notification__c();
                                newNotification.HOT_ServiceResource__c = user.ServiceResources[0].Id; // Fetch ServiceResource ID
                                newNotification.HOT_NotificationChannel__c = 'SMS';
                                newNotification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
                                newNotification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
                                newNotification.HOT_RelatedObject__c = thread.Id;
                                newNotification.HOT_RelatedObjectType__c = 'threadInterpreter';
                                notificationList.add(newNotification);
                            }
                        }
                        //SMS
                        userIdToThreadMapSMS.put(user, userIdToThreadMap.get(user));
                    }
                }
                if (!userIdToThreadMapSMS.isEmpty()) {
                    //SENDER SMS
                    HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(userIdToThreadMapSMS);
                }
            }
            //INSERTE NOTIFIKASJONSRECORD TIL VARSLINGSSENTERET
            insertNotifications(notificationList);
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
