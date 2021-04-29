public without sharing class HOT_RequestNotification {
    public static void notifyDispatchers_requestChanged(List<HOT_Request__c> requests, Map<Id, sObject> triggerOldMap) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        requests = checkWorkOrders(requests);

        List<Id> queueIds = new List<Id>();
        List<Id> editorIds = new List<Id>();
        for (HOT_Request__c request : requests) {
            queueIds.add(request.OwnerId);
            editorIds.add(request.LastModifiedById);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);

        List<GroupMember> groupMembers = [
            SELECT Id, GroupId, UserORGroupId
            FROM GroupMember
            WHERE UserORGroupId IN :editorIds AND GroupId IN :groupByQueue.values()
        ];
        Map<Id, Id> groupByUser = new Map<Id, Id>();
        for (GroupMember grpMem : groupMembers) {
            groupByUser.put(grpMem.UserOrGroupId, grpMem.GroupId);
        }

        for (HOT_Request__c request : requests) {
            if (groupByUser.get(request.LastModifiedById) != groupByQueue.get(request.OwnerId)) {
                HOT_Request__c oldRequest = (HOT_Request__c) triggerOldMap.get(request.Id);

                Set<String> recipients = new Set<String>{ (String) groupByQueue.get(request.OwnerId) };

                // Varsel ved avlyst av bruker
                if (request.Status__c == 'Avlyst' && oldRequest.Status__c != 'Avlyst') {
                    canceledByUser(notificationType, request, recipients);
                }
            }
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
