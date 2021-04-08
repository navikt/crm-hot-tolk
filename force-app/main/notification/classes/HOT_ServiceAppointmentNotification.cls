public without sharing class HOT_ServiceAppointmentNotification {
    public static void notifyInterpreter_serviceAppointmentChanged(
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

    public static void notifyDispatchers_serviceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_Service_Appointment_Changed'
        ];

        List<Id> queueIds = new List<Id>();
        List<Id> requestIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            queueIds.add(serviceAppointment.OwnerId);
            requestIds.add(serviceAppointment.HOT_Request__c);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [SELECT Id, Status__c FROM HOT_Request__c WHERE Id IN :requestIds]
        );

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);

            Set<String> recipients = new Set<String>{ groupByQueue.get(serviceAppointment.OwnerId) };

            // Varsel ved avlyst av tolk
            if (
                oldServiceAppointment.HOT_canceledByInterpreter__c == false &&
                serviceAppointment.HOT_canceledByInterpreter__c == true
            ) {
                resourceCanceled(notificationType, serviceAppointment, recipients);
            }

            // Varsel ved avlyst på vegne av bruker
            if (
                serviceAppointment.Status == 'Canceled' &&
                oldServiceAppointment.Status != 'Canceled' &&
                serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                oldServiceAppointment.Status != 'Scheduled' &&
                requests.get(serviceAppointment.HOT_Request__c).Status__c != 'Avlyst'
            ) {
                canceledByUser(notificationType, serviceAppointment, recipients);
            }
        }
    }

    public static void resourceCanceled(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Set<String> recipients
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Avlyst av tolk:');
        notification.setBody(
            serviceAppointment.AppointmentNumber +
            serviceAppointment.Subject +
            ' avlyst den' +
            serviceAppointment.LastModifiedDate?.format('d.M.yyyy')
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
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
