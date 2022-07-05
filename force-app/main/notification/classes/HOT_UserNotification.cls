public with sharing class HOT_UserNotification {
    public static void notifyUser_requestCreated(List<HOT_Request__c> requests) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_UserNotification'
        ];

        for (HOT_Request__c request : requests) {
            if (request.Account__c != null && request.Person__r.HOT_NotificationChannel__c != null) {
                requestCreatedForYou(notificationType, request, null);
            }
        }
    }

    public static void requestCreatedForYou(
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
