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

        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];

        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }

        if (!threads.isEmpty()) {
            for (Thread__c thread : threads) {
                Boolean isInterpreter = thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ? true : false;
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(thread.CRM_Account__c) != null) {
                    recipients.add(userIdByAccountId.get(thread.CRM_Account__c));
                }
                if (recipients.size() > 0) {
                    if (thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) {
                        HOT_UserNotificationService.newMessageNotification(
                            getCustomNotificationType('HOT_NotifyUser'),
                            thread,
                            isInterpreter,
                            recipients
                        );
                    } else {
                        Set<Id> threadList = new Set<Id>();
                        threadList.add(thread.Id);
                        HOT_ReminderSMSService.sendSMSOnNewMessage(threadList);
                    }
                }
            }
        }
    }

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
                        notification.setNotificationTypeId(
                            getCustomNotificationType('HOT_Service_Appointment_Changed').Id
                        ); // send med parameter for denne
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
                for (User user : userIdToThreadMap.keySet()) {
                    Set<String> recipients = new Set<String>();
                    String notificationChannel = user.ServiceResources[0].HOT_NotificationChannel__c;
                    Thread__c thread = userIdToThreadMap.get(user);
                    if (thread.HOT_Last_message_from__r.AccountId != user.AccountId) {
                        recipients.add(user.Id);
                    }

                    if (recipients.size() > 0) {
                        if (notificationChannel.contains('Push')) {
                            HOT_UserNotificationService.newMessageNotification(
                                getCustomNotificationType('HOT_NotifyUser'),
                                thread,
                                true,
                                recipients
                            );
                        } else {
                            Set<Id> threadList = new Set<Id>();
                            threadList.add(thread.Id);
                            HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(user.Id, thread.Id);
                        }
                    }
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
