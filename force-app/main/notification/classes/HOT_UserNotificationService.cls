public without sharing class HOT_UserNotificationService {
    public static void newRequestNotification(
        CustomNotificationType notificationType,
        HOT_Request__c request,
        Set<String> recipients
    ) {
        String title = 'Andre har lagt inn en bestilling for deg';
        String body;
        if (request.IsSerieoppdrag__c) {
            body = 'Det er bestilt tolk til deg i perioden ' + request.SeriesPeriod__c;
        } else {
            body =
                'Det er bestilt tolk til deg. Dato: ' +
                request.StartTime__c?.format('dd.MM.yyyy', 'Europe/Oslo') +
                ', kl: ' +
                request.StartTime__c?.format('HH:mm', 'Europe/Oslo') +
                ' - ' +
                request.EndTime__c?.format('HH:mm', 'Europe/Oslo') +
                '.';
        }
        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRef(HOT_WorkOrderHandler.getWorkOrder(request).Id, 'R');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);
        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void sendNotificationToOrdererOnStatusUpdate(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        String interpreters,
        Set<String> recipients
    ) {
        String title = 'Status på din bestilling er endret';
        String body;
        if (workOrder.Status == 'Dispatched') {
            body = 'Du har fått tolk. Tolk er ' + interpreters;
        }
        if (workOrder.Status == 'Cannot Complete') {
            body = 'Ikke ledig tolk.';
        }
        body +=
            '\nDato: ' +
            workOrder.StartDate?.format('dd.MM.yyyy', 'Europe/Oslo') +
            ', kl: ' +
            workOrder.StartDate?.format('HH:mm', 'Europe/Oslo') +
            ' - ' +
            workOrder.EndDate?.format('HH:mm', 'Europe/Oslo') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = workOrder.HOT_Request__r.Type__c == 'Me'
            ? getTargetPageRef(workOrder.Id, 'WO')
            : getTargetPageRefOrderer(workOrder.Id, 'WO');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void statusChangeNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        ServiceAppointment sa,
        Set<String> recipients
    ) {
        String title = 'Status på din bestilling er endret';
        String body;
        if (workOrder.Status == 'Dispatched') {
            body =
                'Du har fått tolk. ' +
                (sa.HOT_ServiceResource__r.Name != null ? 'Tolk er ' + sa.HOT_ServiceResource__r.Name + '.' : '');
        }
        if (workOrder.Status == 'Cannot Complete') {
            body = 'Ikke ledig tolk';
        }
        body +=
            '\nDato: ' +
            workOrder.StartDate?.format('dd.MM.yyyy', 'Europe/Oslo') +
            ', kl: ' +
            workOrder.StartDate?.format('HH:mm', 'Europe/Oslo') +
            ' - ' +
            workOrder.EndDate?.format('HH:mm', 'Europe/Oslo') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRef(workOrder.Id, 'WO');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void reminderNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        Set<String> recipients
    ) {
        String title = 'Påminnelse om tolkebestilling';
        String body =
            'Dato: ' +
            workOrder.StartDate?.format('dd.MM.yyyy HH:mm', 'Europe/Oslo') +
            ' - ' +
            workOrder.EndDate?.format('HH:mm', 'Europe/Oslo') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRef(workOrder.Id, 'WO');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void interpreterChangeNotification(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        String interpreters,
        Set<String> recipients
    ) {
        String title = 'Endring av tolk';
        String body =
            'Tolk på din bestilling er endret. \nTolk er: ' +
            interpreters +
            '\nDato: ' +
            workOrder.StartDate?.format('dd.MM.yyyy', 'Europe/Oslo') +
            ', kl: ' +
            workOrder.StartDate?.format('HH:mm', 'Europe/Oslo') +
            ' - ' +
            workOrder.EndDate?.format('HH:mm', 'Europe/Oslo') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRef(workOrder.Id, 'WO');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
    public static void coInterpreterChangeNotification(
        CustomNotificationType notificationType,
        ServiceAppointment sa,
        String interpreters,
        Set<String> recipients
    ) {
        String title = 'Endring av medtolk';
        String body =
            'Medtolk på et oppdrag du er tildelt er blitt endret. \nNy tolk er: ' +
            interpreters +
            '\nDato: ' +
            sa.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
            ', kl: ' +
            sa.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
            ' - ' +
            sa.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
            '.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = HOT_ServiceAppointmentNotification.getTargetPageRefInterpreterOnChanged('my', sa.Id);
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void newMessageNotification(
        CustomNotificationType notificationType,
        Thread__c thread,
        Boolean isFreelanceInterpreter,
        Set<String> recipients
    ) {
        String title = 'Ny melding fra Tolketjenesten';
        String body = 'Du har fått en melding fra Tolketjenesten.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRefThread(thread, isFreelanceInterpreter);
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetPageRef(targetPageRef);
        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void newWantedSRNotification(CustomNotificationType notificationType, Set<String> recipients, String appointmentNumber) {
        String title = 'Du er ønsket til et oppdrag. '+appointmentNumber;
        String body = 'Du kan melde interesse for oppdraget eller avslå.';

        Id notificationTypeId = notificationType.Id;
        String targetPageRef = getTargetPageRefWanted();
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setTargetPageRef(targetPageRef);
        notification.setNotificationTypeId(notificationTypeId);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
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

    private static String getTargetPageRefOrderer(Id targetId, String level) {
        String pageRef =
            '{type: "comm__namedPage",attributes: {pageName: "mine-bestillinger-andre"}, state: {id: "' +
            targetId +
            '", level: "' +
            level +
            '"}}';

        return pageRef;
    }

    private static String getTargetPageRefThread(Thread__c target, Boolean isFreelanceInterpreter) {
        if (
            (target.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' && !target.HOT_IsEmployeeThread__c) ||
            (target.CRM_Thread_Type__c == 'HOT_TOLK-TOLK' ||
            target.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK' ||
            target.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' && isFreelanceInterpreter)
        ) {
            String pageRef =
                '{type: "comm__namedPage",attributes: {pageName: "samtale-frilans"}, state: {recordId: "' +
                target.Id +
                '", from: "mine-samtaler-frilanstolk"}}';
            return pageRef;
        } else {
            String pageRef =
                '{type: "comm__namedPage",attributes: {pageName: "mine-samtaler"}, state: {recordId: "' +
                target.Id +
                '"}}';
            return pageRef;
        }
    }
    private static String getTargetPageRefWanted() {
        String pageRef =
            '{type: "comm__namedPage",attributes: {pageName: "mine-oppdrag"}, state: {list: "' +
            'wanted' +
            '"}}';
        return pageRef;
    }
}
