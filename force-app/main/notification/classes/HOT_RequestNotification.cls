public without sharing class HOT_RequestNotification {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    private static Id notifyDispatcherTypeId;

    private static Id getNotifyDispatcherTypeId() {
        if (notifyDispatcherTypeId == null) {
            notifyDispatcherTypeId = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'HOT_NotifyDispatcher'
                LIMIT 1
            ]
            .Id;
        }
        return notifyDispatcherTypeId;
    }

    public static void notifyDispatchers_requestChanged(List<HOT_Request__c> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Id notificationTypeId = getNotifyDispatcherTypeId();

        List<Id> queueIds = new List<Id>();
        for (HOT_Request__c request : requests) {
            if (request.OwnerId != null) {
                queueIds.add(request.OwnerId);
            }
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);

        for (HOT_Request__c request : requests) {
            Id groupId = groupByQueue.get(request.OwnerId);

            if (groupId == null) {
                continue;
            }
            Set<String> recipients = new Set<String>{ (String) groupId };

            // Varsel ved avlyst av bruker

            canceledByUser(notificationTypeId, request, recipients);
        }
    }

    public static void canceledByUser(Id notificationTypeId, HOT_Request__c request, Set<String> recipients) {
        String title = request.Name + ' - ' + request.StartTime__c?.format('d.M.yyyy') + ' - Avlyst';

        String body =
            'Forespørselen ' +
            request.Name +
            ' som skulle vært gjennomført ' +
            request.StartTime__c?.format('d.M.yyyy') +
            ' ble avlyst.';

        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationTypeId,
            request.Id
        );

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) request);
    }

    @AuraEnabled
    public static void notifyDispatchersFilesUploaded(Id requestId, Id workOrderId, Integer fileCount) {
        if (requestId == null || fileCount == null || fileCount <= 0) {
            return;
        }

        HOT_Request__c request = [
            SELECT Id, Name, Dispatcher__c
            FROM HOT_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];

        String title;
        if (workOrderId != null) {
            title = (fileCount == 1)
                ? 'Nytt vedlegg på arbeidsordre tilhørende ' + request.Name
                : 'Nye vedlegg på arbeidsordre tilhørende ' + request.Name;
        } else {
            title = (fileCount == 1)
                ? 'Nytt vedlegg på forespørsel ' + request.Name
                : 'Nye vedlegg på forespørsel ' + request.Name;
        }
        String body =
            'Det ble lastet opp ' +
            String.valueOf(fileCount) +
            ((fileCount == 1) ? ' vedlegg' : ' vedlegg') +
            ' på ' +
            request.Name +
            '.';

        Id targetId = (workOrderId != null) ? workOrderId : requestId;
        Id notificationTypeId = getNotifyDispatcherTypeId();

        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationTypeId,
            targetId
        );

        Set<String> recipients = new Set<String>();
        if (request.Dispatcher__c != null) {
            recipients.add(request.Dispatcher__c);
        }

        if (!recipients.isEmpty()) {
            try {
                HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) request);
            } catch (Exception e) {
                handleException(e);
            }
        }
    }
}
