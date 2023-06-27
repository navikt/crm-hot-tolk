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
                CRM_Account__r.INT_KrrMobilePhone__c,
                CRM_Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c,
                CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c
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
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(thread.CRM_Account__c) != null) {
                    recipients.add(userIdByAccountId.get(thread.CRM_Account__c));
                }
                if (recipients.size() > 0) {
                    if (thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) {
                        HOT_UserNotificationService.newMessageNotification(
                            getCustomNotificationType('HOT_NotifyUser'),
                            thread,
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

    public static CustomNotificationType getCustomNotificationType(String devName) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = :devName
        ];
        return notificationType;
    }
}
