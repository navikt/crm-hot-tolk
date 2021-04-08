public without sharing class HOT_RequestNotification {
    public static void notifyDispatchers_requestChanged(List<HOT_Request__c> requests, Map<Id, sObject> triggerOldMap) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_Service_Appointment_Changed'
        ];

        List<Id> queueIds = new List<Id>();
        for (HOT_Request__c request : requests) {
            queueIds.add(request.OwnerId);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Map<Id, Set<String>> recipientsByGroupId = HOT_NotificationHandler.getUsersInGroup(groupByQueue.values());

        for (HOT_Request__c request : requests) {
            HOT_Request__c oldRequest = (HOT_Request__c) triggerOldMap.get(request.Id);

            Set<String> recipients = recipientsByGroupId.get(groupByQueue.get(request.OwnerId));

            // Varsel ved avlyst av bruker
            if (request.Status__c == 'Avlyst' && oldRequest.Status__c != 'Avlyst') {
                canceledByUser(notificationType, request, recipients);
            }
        }
    }
    public static void canceledByUser(
        CustomNotificationType notificationType,
        HOT_Request__c request,
        Set<String> recipients
    ) {
        String title = request.Name + ' - ' + request.StartTime__c?.format('d.M.yyyy') + ' - ' + ' Avlyst';
        String body =
            request.LastModifiedBy +
            ' avlyste ' +
            'forespørselen ' +
            request.Name +
            ' som skulle vært gjennomført ' +
            request.StartTime__c?.format('d.M.yyyy');

        Id notificationTypeId = notificationType.Id;
        Id targetId = request.Id;
        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationTypeId,
            targetId
        );
        HOT_NotificationHandler.sendNotification(notification, recipients);
    }
}
