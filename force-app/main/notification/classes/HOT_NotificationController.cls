public without sharing class HOT_NotificationController {
    public static HOT_Notification__c createNotificationServiceAppointment(
        ServiceAppointment sa,
        String saEvent,
        Boolean isSmsNotification
    ) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_ServiceResource__c = sa.HOT_ServiceResource__r.Id;
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
            subject = 'INFO\n';
            if (saEvent == 'Dispatched') {
                subject += 'Du er tildelt oppdraget ';
            }
            if (saEvent == 'Removed') {
                subject += 'Du er tatt av oppdraget ';
            }
            subject += sa.AppointmentNumber;
            if (saEvent == 'Address') {
                subject +=
                    ' ' +
                    HOT_ReminderSMSService.formatTimePeriod(sa.EarliestStartTime, sa.DueDate) +
                    ' har endret adresse';
            }
            if (saEvent == 'Time') {
                subject +=
                    ' har endret tidspunkt.\nNy tid er ' +
                    HOT_ReminderSMSService.formatTimePeriod(sa.EarliestStartTime, sa.DueDate);
            }
            if (saEvent == 'CanceledByUser') {
                subject +=
                    ' ' +
                    HOT_ReminderSMSService.formatTimePeriod(sa.EarliestStartTime, sa.DueDate) +
                    ' er avlyst';
            }
            if (saEvent == 'Screen') {
                subject +=
                    ' ' +
                    HOT_ReminderSMSService.formatTimePeriod(sa.EarliestStartTime, sa.DueDate) +
                    ' er endret';
            }
            if (saEvent == 'Dispatched') {
                subject += '\n' + HOT_ReminderSMSService.formatTimePeriodExtended(sa.EarliestStartTime, sa.DueDate);
            }
            if (saEvent == 'Removed') {
                subject += '\n' + HOT_ReminderSMSService.formatTimePeriodExtended(sa.EarliestStartTime, sa.DueDate);
            }
            return subject;
        }
        if (saEvent == 'Removed') {
            subject =
                sa.AppointmentNumber +
                ' - ' +
                sa.EarliestStartTime?.format('d.M.yyyy') +
                ' - ' +
                'Tatt av oppdraget';
        }
        if (saEvent == 'Dispatched') {
            subject = 'Du er tildelt oppdraget ' + sa.AppointmentNumber;
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
        if (saEvent == 'Dispatched') {
            message =
                'Tidspunkt for oppdraget er ' +
                sa.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                ' - ' +
                sa.DueDate?.format('HH:mm') +
                '.';
        }
        return message;
    }
    //getting type used for navigation when clicking on the notification on experience site
    public static String getRelatedObjectType(String saEvent) {
        String relatedObjectType = '';
        if (saEvent == 'Removed') {
            relatedObjectType = 'noServiceAppointment';
        }
        return relatedObjectType;
    }
}
