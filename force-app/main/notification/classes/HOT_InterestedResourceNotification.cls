public without sharing class HOT_InterestedResourceNotification {
    public static void newWantedSR(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Set<String> recipients
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(
            serviceAppointment.AppointmentNumber +
            ' - ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
            ' - ' +
            'Tatt av oppdraget'
        );
        notification.setBody(
            'Du er tatt av oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ' som skulle starte ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm')
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
    }
}