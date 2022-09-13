public without sharing class HOT_UserNotificationService {
    public static void newRequestNotification(
        CustomNotificationType notificationType,
        HOT_Request__c request,
        Set<String> recipients
    ) {
        String title = 'Andre har lagt inn en bestilling for deg';
        String body =
            'Det er bestilt tolk til deg. Dato: ' +
            request.StartTime__c?.format('d.M.yyyy, hh:mm') +
            ' - ' +
            request.EndTime__c?.format('hh:mm') +
            '.';

        Id notificationTypeId = notificationType.Id;
        Id targetId = request.Id;
        String targetPageRef = getTargetPageRef(request.Id, 'R');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        notification.send(recipients);
    }

    public static void statusChangeNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        Set<String> recipients
    ) {
        String title = 'Endring av status';
        String body =
            'Status på din bestilling er endret til: ' +
            workOrder.Status +
            '. ' +
            (workOrder.HOT_Interpreters__c != null ? 'Tolk er ' + workOrder.HOT_Interpreters__c + '.' : '') +
            'Dato: ' +
            workOrder.StartDate?.format('d.M.yyyy, hh:mm') +
            ' - ' +
            workOrder.EndDate?.format('hh:mm') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRef(workOrder.Id, 'WO');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        notification.send(recipients);
    }

    public static void interpreterChangeNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        Set<String> recipients
    ) {
        String title = 'Endring av tolk';
        String body =
            'Tolk på din bestilling er endret. ' +
            'Tolk er ' +
            workOrder.HOT_Interpreters__c +
            '.' +
            'Dato: ' +
            workOrder.StartDate?.format('d.M.yyyy, hh:mm') +
            ' - ' +
            workOrder.EndDate?.format('hh:mm') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRef(workOrder.Id, 'WO');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        notification.send(recipients);
    }

    public static void newMessageNotification(
        CustomNotificationType notificationType,
        Thread__c thread,
        Set<String> recipients
    ) {
        String title = 'Ny melding fra Tolketjenesten';
        String body = 'Du har fått en melding fra Tolketjenesten.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRefThread(thread.Id);
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        notification.send(recipients);
    }

    private static String getTargetPageRef(Id targetId, String level) {
        String pageRef =
            '{type: "comm__namedPage",attributes: {pageName: "mine-bestillinger"}, state: {id: "' +
            targetId +
            '", level: "' +
            level +
            '"}}';
        return pageRef;
    }

    private static String getTargetPageRefThread(Id targetId) {
        String pageRef =
            '{type: " comm__externalRecordPage",attributes: {recordId: ' +
            targetId +
            ', objectType: "Thread__c"}}';
        return pageRef;
    }
}
