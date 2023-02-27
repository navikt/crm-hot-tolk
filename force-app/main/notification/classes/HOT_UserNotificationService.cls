public without sharing class HOT_UserNotificationService {
    public static void newWorkOrderNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        Set<String> recipients)
        {

    //                 // Instantiating a notification
    //     Messaging.PushNotification msg = 
    //     new Messaging.PushNotification();

    // // Assembling the necessary payload parameters for Apple.
    // // Apple params are: 
    // // (<alert text>,<alert sound>,<badge count>,
    // // <free-form data>)
    // // This example doesn't use badge count or free-form data.
    // // The number of notifications that haven't been acted
    // // upon by the intended recipient is best calculated
    // // at the time of the push. This timing helps
    // // ensure accuracy across multiple target devices.
    // Map<String, Object> payload = 
    //     Messaging.PushNotificationPayload.apple(
    //         'Dick ' + workOrder.Subject + ' status changed to: ' 
    //         + workOrder.Status, '', null, null);

    // // Adding the assembled payload to the notification
    //  msg.setPayload(payload);                    

    // // Sending the notification to the specified app and users.
    // // Here we specify the API name of the connected app.  
    //     msg.send('myCommunities Playground for iOS', recipients);

    // }
        String title = 'Andre har lagt inn en bestilling for deg';
        String body =
            'Det er bestilt tolk til deg. Dato: ' +
            workOrder.StartDate?.format('d.M.yyyy, hh:mm') +
            ' - ' +
            workOrder.EndDate?.format('hh:mm') +
            '.';

        Id notificationTypeId = notificationType.Id;
        //String targetId = workOrder.Id;
        String targetId = workOrder.HOT_Request__c;
       // String targetPageRef = getTargetPageRef(workOrder.Id, 'R');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(targetId);
       // notification.setTargetPageRef(targetPageRef);

        try {
            notification.send(recipients);
            System.debug('Notification stats ' + notification);
        } catch (Exception e) {
            System.debug('Problem sending notification' + e.getMessage());
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
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
