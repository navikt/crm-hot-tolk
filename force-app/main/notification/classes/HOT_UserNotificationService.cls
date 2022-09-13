public without sharing class HOT_UserNotificationService {
    public static void newWorkOrderNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        Set<String> recipients
    ) {
        String title = 'Andre har lagt inn en bestilling for deg';
        String body =
            'Det er bestilt tolk til deg. Dato: ' +
            workOrder.StartDate?.format('d.M.yyyy, hh:mm') +
            ' - ' +
            workOrder.EndDate?.format('hh:mm') +
            '.';

        Id notificationTypeId = notificationType.Id;
        Id targetId = workOrder.Id;
        String targetPageRef = getTargetPageRef(workOrder.Id, 'R');
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

    public static void testNotification(Id threadId) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Thread__c thread = new Thread__c(Id = threadId);
        Set<String> recipients = new Set<String>{ '0051X00000Cryk9QAB' };

        WorkOrder workOrder = [SELECT Id, StartDate, EndDate FROM workOrder WHERE Id = '0WO1X000001WGGbWAO'];
        newMessageNotification(notificationType, thread, recipients);
        newWorkOrderNotification(notificationType, workOrder, recipients);
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
        //notification.setTargetId('a0T1X000004EOdMUAW');
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
            '{type: "standard__recordPage",attributes: {recordId: "' +
            targetId +
            '", objectApiName: "Thread__c", actionName: "view"}}';
        return pageRef;
    }
}
