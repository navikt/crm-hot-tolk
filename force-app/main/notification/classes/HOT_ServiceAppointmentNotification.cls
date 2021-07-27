public without sharing class HOT_ServiceAppointmentNotification {
    public static void resourceServiceAppointmentChanged(
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
            // Varsel ved tildelt tolk
            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                (oldServiceAppointment.Status != serviceAppointment.Status ||
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c) &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                Set<String> recipients = new Set<String>{ serviceAppointment.HOT_AssignedResourceId__c };

                resourceAdded(notificationType, serviceAppointment, recipients);
            }

            if (oldServiceAppointment.HOT_AssignedResourceId__c != null) {
                Set<String> recipients = new Set<String>{ oldServiceAppointment.HOT_AssignedResourceId__c };

                // Varsel ved avlyst av bruker
                if (
                    serviceAppointment.Status == 'Canceled' &&
                    oldServiceAppointment.Status != 'Canceled' &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                    oldServiceAppointment.Status != 'Scheduled' &&
                    recipients != null &&
                    !recipients.contains(serviceAppointment.LastModifiedById) &&
                    serviceAppointment.HOT_CancelComment__c == null
                ) {
                    canceledByUser(notificationType, serviceAppointment, recipients);
                }

                // Varsel ved endring av tidspunkt
                if (
                    (serviceAppointment.SchedStartTime != oldServiceAppointment.SchedStartTime ||
                    serviceAppointment.SchedEndTime != oldServiceAppointment.SchedEndTime) &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                    serviceAppointment.Status != 'Scheduled' &&
                    serviceAppointment.SchedStartTime != null &&
                    oldServiceAppointment.SchedStartTime != null
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
                    serviceAppointment.Status == 'None') &&
                    serviceAppointment.HOT_CanceledByInterpreter__c == false
                ) {
                    resourceChanged(notificationType, serviceAppointment, recipients);
                }

                // Varsel ved endring av skjermtolk/oppmøtetolk
                if (
                    serviceAppointment.HOT_IsScreenInterpreterNew__c !=
                    oldServiceAppointment.HOT_IsScreenInterpreterNew__c &&
                    serviceAppointment.Status != 'Scheduled'
                ) {
                    String isScreenInterpreterString = serviceAppointment.HOT_IsScreenInterpreterNew__c
                        ? 'skjermtolk'
                        : 'oppmøtetolk';
                    screenInterpreterChanged(
                        notificationType,
                        serviceAppointment,
                        recipients,
                        isScreenInterpreterString
                    );
                }
            }
        }
    }

    public static void dispatcherServiceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        List<Id> queueIds = new List<Id>();
        List<Id> workOrderLineItemIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            queueIds.add(serviceAppointment.OwnerId);
            workOrderLineItemIds.add(serviceAppointment.HOT_WorkOrderLineItem__c);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>(
            [SELECT Id, Status FROM WorkOrderLineItem WHERE Id IN :workOrderLineItemIds AND Status != 'Annul']
        );

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);

            Set<String> recipients = new Set<String>{ (String) groupByQueue.get(serviceAppointment.OwnerId) };

            // Varsel ved avlyst av tolk
            if (
                oldServiceAppointment.HOT_CanceledByInterpreter__c == false &&
                serviceAppointment.HOT_CanceledByInterpreter__c == true
            ) {
                resourceCanceled(notificationType, serviceAppointment, recipients);
            }

            // Varsel ved avlyst på vegne av bruker
            if (serviceAppointment.Status == 'Canceled' && oldServiceAppointment.Status != 'Canceled') {
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
        notification.setTitle('Avlyst av tolk: ' + serviceAppointment.AppointmentNumber);
        notification.setBody(
            'Tolken meldte seg av ' +
            serviceAppointment.AppointmentNumber +
            ' ' +
            serviceAppointment.Subject +
            ' den ' +
            serviceAppointment.LastModifiedDate?.format('d.M.yyyy HH:mm')
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
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
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
            ' er avlyst.'
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
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
            'endret tidspunkt'
        );
        notification.setBody(
            'Nytt tidspunkt er ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy HH:mm') +
            ' - ' +
            serviceAppointment.SchedEndTime?.format('HH:mm')
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
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
            serviceAppointment.SchedStartTime?.format('d.M.yyyy HH:mm') +
            ' - ' +
            'endret adresse'
        );
        notification.setBody('Ny adresse er ' + serviceAppointment.HOT_AddressFormated__c);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
    }

    public static void resourceAdded(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Set<String> recipients
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Du er tildelt oppdraget ' + serviceAppointment.AppointmentNumber);
        notification.setBody(
            'Tidspunkt for oppdraget er ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy HH:mm') +
            ' - ' +
            serviceAppointment.SchedEndTime?.format('HH:mm') +
            '.'
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
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

    public static void screenInterpreterChanged(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Set<String> recipients,
        String isScreenInterpreterString
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(
            serviceAppointment.AppointmentNumber +
            ' - ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy HH:mm') +
            ' - ' +
            'endret til ' +
            isScreenInterpreterString
        );
        notification.setBody(
            'Oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ', ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy HH:mm') +
            ' - ' +
            serviceAppointment.SchedEndTime?.format('HH:mm') +
            ' ble endret til ' +
            isScreenInterpreterString
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
    }
}
