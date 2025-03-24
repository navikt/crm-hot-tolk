public without sharing class HOT_NotificationController {
    public static HOT_Notification__c createNotificationServiceAppointment(
        ServiceAppointment sa,
        String saEvent,
        Boolean isSmsNotification
    ) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_ServiceResource__c = sa.HOT_AssignedResourceId__c;
        notification.HOT_NotificationChannel__c = isSmsNotification == true ? 'SMS' : 'Push-varsel i appen';
        notification.HOT_Subject__c = constructNotificationSubject(sa, saEvent, isSmsNotification);
        notification.HOT_NotificationText__c = constructNotificationMessage(sa, saEvent, isSmsNotification);
        notification.HOT_RelatedObject__c = sa.Id;
        notification.HOT_RelatedObjectType__c = getRelatedObjectType(saEvent);

        return notification;
    }
    public static String constructNotificationSubject(
        ServiceAppointment sa,
        String saEvent,
        Boolean isSmsNotification
    ) {
        String subject = '';
        if (isSmsNotification) {
            return subject = HOT_ReminderSMSService.constructMessageToInterpreter(sa, saEvent);
        }
        if (saEvent == 'Removed') {
            subject =
                sa.AppointmentNumber +
                ' - ' +
                sa.EarliestStartTime?.format('d.M.yyyy') +
                ' - ' +
                'Tatt av oppdraget';
        }
        return subject;
    }
    public static String constructNotificationMessage(
        ServiceAppointment sa,
        String saEvent,
        Boolean isSmsNotification
    ) {
        String message = '';
        if (isSmsNotification) {
            message += 'For mer informasjon, se tolkebestilling.nav.no.\n';
            message += 'Du kan ikke svare på denne meldingen.\n';
            message += 'Mvh tolketjenesten i Nav';
            return message;
        }
        if (saEvent == 'Removed') {
            message =
                'Du er tatt av oppdraget ' +
                sa.AppointmentNumber +
                ' som skulle starte ' +
                sa.EarliestStartTime?.format('d.M.yyyy HH:mm');
        }
        return message;
    }
    public static String getRelatedObjectType(String saEvent) {
        String relatedObjectType = '';
        if (saEvent == 'Removed') {
            relatedObjectType = 'noServiceAppointment';
        }
        return relatedObjectType;
    }
}
