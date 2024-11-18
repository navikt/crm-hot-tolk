public without sharing class HOT_RequestNotification {
    public static void notifyDispatchers_requestChanged(List<HOT_Request__c> requests) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        List<Id> queueIds = new List<Id>();
        for (HOT_Request__c request : requests) {
            queueIds.add(request.OwnerId);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);

        List<GroupMember> groupMembers = [
            SELECT Id, GroupId, UserORGroupId
            FROM GroupMember
            WHERE GroupId IN :groupByQueue.values()
        ];

        for (HOT_Request__c request : requests) {
            Set<String> recipients = new Set<String>{ (String) groupByQueue.get(request.OwnerId) };

            // Varsel ved avlyst av bruker

            canceledByUser(notificationType, request, recipients);
        }
    }
    public static void canceledByUser(
        CustomNotificationType notificationType,
        HOT_Request__c request,
        Set<String> recipients
    ) {
        String title = request.Name + ' - ' + request.StartTime__c?.format('d.M.yyyy') + ' - ' + 'Avlyst';
        String body =
            'Forespørselen ' +
            request.Name +
            ' som skulle vært gjennomført ' +
            request.StartTime__c?.format('d.M.yyyy') +
            ' ble avlyst.';

        Id notificationTypeId = notificationType.Id;
        Id targetId = request.Id;
        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationTypeId,
            targetId
        );
        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) request);
    }
}
