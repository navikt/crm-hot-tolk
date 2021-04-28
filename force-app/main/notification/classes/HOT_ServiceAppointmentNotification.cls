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
            if (
                serviceAppointment.Status == 'Canceled' &&
                oldServiceAppointment.Status != 'Canceled' &&
                serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                oldServiceAppointment.Status != 'Scheduled' &&
                workOrderLineItems.get(serviceAppointment.HOT_WorkOrderLineItem__c) != null &&
                workOrderLineItems.get(serviceAppointment.HOT_WorkOrderLineItem__c).Status != 'Canceled' &&
                serviceAppointment.HOT_CancelComment__c != null
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
            'Tolken meldte seg av ' +
            serviceAppointment.AppointmentNumber +
            ' ' +
            serviceAppointment.Subject +
            ' den ' +
            serviceAppointment.LastModifiedDate?.format('d.M.yyyy')
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
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
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
            'Oppdraget ' +
            serviceAppointment.AppointmentNumber +
            ' den ' +
            serviceAppointment.SchedStartTime?.format('d.M.yyyy') +
            ' har fått nytt tidspunkt.'
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
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
            ' - ' +
            'endret adresse'
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
            ' den ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy')
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
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
            ' - ' +
            'endret til ' +
            isScreenInterpreterString
        );
        notification.setBody(
            serviceAppointment.AppointmentNumber +
            ' den ' +
            serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
            ' ble endret til ' +
            isScreenInterpreterString
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
    }
}
