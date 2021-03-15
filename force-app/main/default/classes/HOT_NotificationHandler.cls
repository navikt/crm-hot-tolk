public without sharing class HOT_NotificationHandler {
    public static void serviceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_Service_Appointment_Changed'
        ];

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);

            Set<String> recipients = new Set<String>{ oldServiceAppointment.HOT_AssignedResourceId__c };

            // Varsel ved avlyst av bruker
            if (
                serviceAppointment.Status == 'Canceled' &&
                oldServiceAppointment.Status != 'Canceled' &&
                serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                oldServiceAppointment.Status != 'Scheduled'
            ) {
                canceledByUser(notificationType, serviceAppointment, recipients);
            }

            // Varsel ved endring av tidspunkt
            if (
                (serviceAppointment.SchedStartTime != oldServiceAppointment.SchedStartTime ||
                serviceAppointment.SchedEndTime != oldServiceAppointment.SchedEndTime) &&
                serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                serviceAppointment.Status != 'Scheduled' &&
                serviceAppointment.SchedStartTime != null
            ) {
                timeChanged(notificationType, serviceAppointment, recipients);
            }

            // Varsel ved endring av adresse
            if (
                serviceAppointment.HOT_AddressFormated__c != oldServiceAppointment.HOT_AddressFormated__c &&
                serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                serviceAppointment.Status != 'Scheduled'
            ) {
                addressChanged(notificationType, serviceAppointment, recipients);
            }

            // Varsel ved fjerning av tolk
            if (
                (oldServiceAppointment.Status == 'Completed' ||
                oldServiceAppointment.Status == 'Dispatched' ||
                oldServiceAppointment.Status == 'In Progress') &&
                (serviceAppointment.Status == null ||
                serviceAppointment.Status == 'None')
            ) {
                resourceChanged(notificationType, serviceAppointment, recipients);
            }
        }
    }

    public static void canceledByUser(
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
            ' Avlyst'
        );
        notification.setBody(
            'Oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ' som skulle vært gjennomført ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
            ' er avlyst.'
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

    public static void timeChanged(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Set<String> recipients
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(
            serviceAppointment.AppointmentNumber +
            ' - ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy') +
            ' - ' +
            ' Endret tidspunkt'
        );
        notification.setBody(
            'Oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ' den ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy') +
            ' har fått nytt tidspunkt.'
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

    public static void addressChanged(
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
            ' Endret adresse'
        );
        notification.setBody(
            'Oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ' den ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
            ' har fått ny adresse.'
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

    public static void resourceChanged(
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
            ' Tatt av oppdraget'
        );
        notification.setBody(
            'Du er tatt av oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ' den ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy')
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
}
