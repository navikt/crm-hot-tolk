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
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            // Varsel ved tildelt tolk eller udekket
            if (
                (serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Dispatched') ||
                (serviceAppointment.HOT_AssignedResourceId__c == null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Cannot Complete')
            ) {
                Set<String> interpreterRecipients = new Set<String>{ serviceAppointment.HOT_AssignedResourceId__c };
                Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                if (serviceAppointment.HOT_AssignedResourceId__c != null) {
                    resourceAdded(notificationType, saIds, interpreterRecipients);
                }
            }

            // Varsel ved endring av tolk
            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                Set<String> interpreterRecipients = new Set<String>{ serviceAppointment.HOT_AssignedResourceId__c };
                Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                resourceAdded(notificationType, saIds, interpreterRecipients);

                notifyUserOnChangedResource(serviceAppointment);
                notifyInterpretersOnChangedResource(serviceAppointment);
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
                    Set<Id> srIds = new Set<Id>{ oldServiceAppointment.HOT_ServiceResource__c };
                    canceledByUser(notificationType, serviceAppointment, srIds, recipients);
                }

                // Varsel ved endring av tidspunkt
                if (
                    (serviceAppointment.EarliestStartTime != oldServiceAppointment.EarliestStartTime ||
                    serviceAppointment.DueDate != oldServiceAppointment.DueDate) &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                    serviceAppointment.Status != 'Scheduled' &&
                    serviceAppointment.EarliestStartTime != null &&
                    oldServiceAppointment.DueDate != null
                ) {
                    Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                    timeChanged(notificationType, saIds, recipients);
                }

                // Varsel ved endring av adresse
                if (
                    serviceAppointment.HOT_AddressFormated__c != oldServiceAppointment.HOT_AddressFormated__c &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                    serviceAppointment.Status != 'Scheduled'
                ) {
                    Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                    addressChanged(notificationType, saIds, recipients);
                }

                // Varsel ved fjerning av tolk
                if (
                    (oldServiceAppointment.Status == 'Completed' ||
                    oldServiceAppointment.Status == 'Dispatched' ||
                    oldServiceAppointment.Status == 'In Progress') &&
                    (serviceAppointment.Status == null ||
                    serviceAppointment.Status == 'Scheduled' ||
                    serviceAppointment.Status == 'None') &&
                    serviceAppointment.HOT_CanceledByInterpreter__c == false
                ) {
                    Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                    resourceChanged(notificationType, saIds, recipients);
                }

                // Varsel ved endring av skjermtolk/oppmøtetolk
                if (
                    serviceAppointment.HOT_IsScreenInterpreterNew__c !=
                    oldServiceAppointment.HOT_IsScreenInterpreterNew__c &&
                    serviceAppointment.Status != 'Scheduled'
                ) {
                    Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                    String isScreenInterpreterString = serviceAppointment.HOT_IsScreenInterpreterNew__c
                        ? 'skjermtolk'
                        : 'oppmøtetolk';
                    screenInterpreterChanged(notificationType, saIds, recipients, isScreenInterpreterString);
                }
            }
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
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
                Set<Id> srIds = new Set<Id>{ oldServiceAppointment.HOT_ServiceResource__c };
                canceledByUser(notificationType, serviceAppointment, srIds, recipients);
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
                Datetime.now().format('d.M.yyyy HH:mm')
        );
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(serviceAppointment.Id);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
    }

    public static void canceledByUser(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Set<Id> srIds,
        Set<String> recipients
    ) {
        ServiceResource serviceResource = [
            SELECT HOT_NotificationChannel__c, AccountId
            FROM ServiceResource
            WHERE Id IN :srIds AND HOT_NotificationChannel__c != NULL
            LIMIT 1
        ];
        Set<Id> saSMS = new Set<Id>();
        List<String> recipientList = new List<String>(recipients);
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        if (
            serviceResource.HOT_NotificationChannel__c.contains('Push') ||
            serviceAppointment.HOT_IsEmployedInterpreter__c
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
            //creating notification object
            if (serviceResource.AccountId != null) {
                HOT_Notification__c newNotification = new HOT_Notification__c();
                newNotification.HOT_Account__c = serviceResource.AccountId;
                newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                newNotification.HOT_Subject__c =
                    serviceAppointment.AppointmentNumber +
                    ' - ' +
                    serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
                    ' - ' +
                    ' Avlyst';
                newNotification.HOT_NotificationText__c =
                    'Oppdraget ' +
                    serviceAppointment.AppointmentNumber +
                    ' som skulle vært gjennomført ' +
                    serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                    ' er avlyst.';
                newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                newNotification.HOT_RelatedObjectType__c = 'noServiceAppointment';

                notificationList.add(newNotification);
            }
        } else {
            saSMS.add(serviceAppointment.Id);
            //creating notification object
            if (serviceResource.AccountId != null) {
                HOT_Notification__c newNotification = new HOT_Notification__c();
                newNotification.HOT_Account__c = serviceResource.AccountId;
                newNotification.HOT_NotificationChannel__c = 'SMS';
                newNotification.HOT_Subject__c = 'INFO ' + serviceAppointment.AppointmentNumber + ' er avlyst.';
                newNotification.HOT_NotificationText__c =
                    'For mer informasjon, se tolkebestilling.nav.no.\n' +
                    'Du kan ikke svare på denne meldingen.\n' +
                    'Mvh tolketjenesten i NAV';
                newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                newNotification.HOT_RelatedObjectType__c = 'noServiceAppointment';

                if (newNotification.HOT_Account__c != null) {
                    notificationList.add(newNotification);
                }
            }
        }
        if (saSMS.size() > 0) {
            HOT_ReminderSMSService.sendSMSToInterpreterOnCanceledByUser(saSMS, srIds);
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public static void timeChanged(CustomNotificationType notificationType, Set<Id> saIds, Set<String> recipients) {
        Set<Id> saSMS = new Set<Id>();
        List<ServiceAppointment> saList = [
            SELECT
                AppointmentNumber,
                EarliestStartTime,
                DueDate,
                HOT_AssignedResourceId__c,
                HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_ServiceResource__r.AccountId
            FROM ServiceAppointment
            WHERE Id IN :saIds AND HOT_ServiceResource__r.HOT_NotificationChannel__c != NULL
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<Id, Id> userIdToAccountMap = new Map<Id, Id>();
        Set<Id> asUserIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : saList) {
            asUserIds.add(serviceAppointment.HOT_AssignedResourceId__c);
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE Id IN :asUserIds];
        for (User user : users) {
            userIdToAccountMap.put(user.Id, user.AccountId);
        }

        for (ServiceAppointment serviceAppointment : saList) {
            if (
                serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push') ||
                serviceAppointment.HOT_IsEmployedInterpreter__c
            ) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(
                    serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
                        ' - ' +
                        'endret tidspunkt'
                );
                notification.setBody(
                    'Nytt tidspunkt er ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm')
                );
                if (!serviceAppointment.HOT_IsEmployedInterpreter__c) {
                    String targetPageRef = getTargetPageRefInterpreter('my', serviceAppointment.Id);
                    notification.setTargetPageRef(targetPageRef);
                }
                //String targetPageRef = getTargetPageRefInterpreter('interested', getHARs(serviceAppointment.Id));
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(serviceAppointment.Id);

                HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c =
                        serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
                        ' - ' +
                        'endret tidspunkt';
                    newNotification.HOT_NotificationText__c =
                        'Nytt tidspunkt er ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm');
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            } else {
                saSMS.add(serviceAppointment.Id);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'SMS';
                    newNotification.HOT_Subject__c =
                        'INFO '+serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        ' har endret tidspunkt.';
                        
                    newNotification.HOT_NotificationText__c =
                        'For mer informasjon, se tolkebestilling.nav.no.\n' +
                        'Du kan ikke svare på denne meldingen.\n' +
                        'Mvh tolketjenesten i NAV';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            }
        }
        if (saSMS.size() > 0) {
            HOT_ReminderSMSService.sendSMSToInterpreterOnTimeChanged(saSMS);
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public static void addressChanged(CustomNotificationType notificationType, Set<Id> saIds, Set<String> recipients) {
        Set<Id> saSMS = new Set<Id>();
        List<ServiceAppointment> saList = [
            SELECT
                AppointmentNumber,
                EarliestStartTime,
                HOT_AddressFormated__c,
                HOT_AssignedResourceId__c,
                HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                DueDate
            FROM ServiceAppointment
            WHERE Id IN :saIds AND HOT_ServiceResource__r.HOT_NotificationChannel__c != NULL
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<Id, Id> userIdToAccountMap = new Map<Id, Id>();
        Set<Id> asUserIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : saList) {
            asUserIds.add(serviceAppointment.HOT_AssignedResourceId__c);
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE Id IN :asUserIds];
        for (User user : users) {
            userIdToAccountMap.put(user.Id, user.AccountId);
        }

        for (ServiceAppointment serviceAppointment : saList) {
            if (
                serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push') ||
                serviceAppointment.HOT_IsEmployedInterpreter__c
            ) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(
                    serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        'endret adresse'
                );
                notification.setBody('Ny adresse er ' + serviceAppointment.HOT_AddressFormated__c);
                if (!serviceAppointment.HOT_IsEmployedInterpreter__c) {
                    String targetPageRef = getTargetPageRefInterpreter('my', serviceAppointment.Id);
                    notification.setTargetPageRef(targetPageRef);
                }
                //String targetPageRef = getTargetPageRefInterpreter('interested', getHARs(serviceAppointment.Id));
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(serviceAppointment.Id);

                HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c =
                        serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        'endret adresse';
                    newNotification.HOT_NotificationText__c =
                        'Ny adresse er ' + serviceAppointment.HOT_AddressFormated__c;
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            } else {
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    saSMS.add(serviceAppointment.Id);
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'SMS';
                    newNotification.HOT_Subject__c =
                        'INFO\n' +
                        serviceAppointment.AppointmentNumber +' '+serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        ' har endret adresse.';
                    newNotification.HOT_NotificationText__c =
                        'For mer informasjon, se tolkebestilling.nav.no.\n' +
                        'Du kan ikke svare på denne meldingen.\n' +
                        'Mvh tolketjenesten i NAV';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            }
        }
        if (saSMS.size() > 0) {
            HOT_ReminderSMSService.sendSMSToInterpreterOnAddressChanged(saSMS);
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public static void resourceAdded(CustomNotificationType notificationType, Set<Id> saIds, Set<String> recipients) {
        Set<Id> saSMS = new Set<Id>();
        List<ServiceAppointment> saList = [
            SELECT
                AppointmentNumber,
                HOT_IsEmployedInterpreter__c,
                EarliestStartTime,
                DueDate,
                HOT_AssignedResourceId__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Id IN :saIds AND HOT_ServiceResource__r.HOT_NotificationChannel__c != NULL
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<Id, Id> userIdToAccountMap = new Map<Id, Id>();
        Set<Id> asUserIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : saList) {
            asUserIds.add(serviceAppointment.HOT_AssignedResourceId__c);
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE Id IN :asUserIds];
        for (User user : users) {
            userIdToAccountMap.put(user.Id, user.AccountId);
        }

        for (ServiceAppointment serviceAppointment : saList) {
            if (
                serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push') ||
                serviceAppointment.HOT_IsEmployedInterpreter__c
            ) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Du er tildelt oppdraget ' + serviceAppointment.AppointmentNumber);
                notification.setBody(
                    'Tidspunkt for oppdraget er ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        '.'
                );
                if (!serviceAppointment.HOT_IsEmployedInterpreter__c) {
                    String targetPageRef = getTargetPageRefInterpreter('my', serviceAppointment.Id);
                    notification.setTargetPageRef(targetPageRef);
                }
                //String targetPageRef = getTargetPageRefInterpreter('interested', getHARs(serviceAppointment.Id));
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(serviceAppointment.Id);

                HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c = 'Du er tildelt oppdraget ' + serviceAppointment.AppointmentNumber;
                    newNotification.HOT_NotificationText__c =
                        'Tidspunkt for oppdraget er ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        '.';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            } else {
                saSMS.add(serviceAppointment.Id);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'SMS';
                    newNotification.HOT_Subject__c =
                        'INFO\n Du er tildelt oppdraget ' + serviceAppointment.AppointmentNumber;
                    newNotification.HOT_NotificationText__c =
                        'Dato: ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        '.\n';
                    newNotification.HOT_NotificationText__c +=
                        '\nFor mer informasjon, se tolkebestilling.nav.no.\n' +
                        'Du kan ikke svare på denne meldingen.\n' +
                        'Mvh tolketjenesten i NAV';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            }
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
        if (saSMS.size() > 0) {
            HOT_ReminderSMSService.sendSMSToInterpreterOnAddedOrChanged(saSMS);
        }
    }

    public static void resourceChanged(CustomNotificationType notificationType, Set<Id> saIds, Set<String> recipients) {
        Set<Id> saSMS = new Set<Id>();
        List<ServiceAppointment> saList = [
            SELECT
                AppointmentNumber,
                HOT_IsEmployedInterpreter__c,
                EarliestStartTime,
                DueDate,
                HOT_AssignedResourceId__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Id IN :saIds AND HOT_ServiceResource__r.HOT_NotificationChannel__c != NULL
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<Id, Id> userIdToAccountMap = new Map<Id, Id>();

        List<User> users = [SELECT Id, AccountId FROM User WHERE Id IN :recipients];
        for (User user : users) {
            userIdToAccountMap.put(user.Id, user.AccountId);
        }

        for (ServiceAppointment serviceAppointment : saList) {
            if (
                serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push') ||
                serviceAppointment.HOT_IsEmployedInterpreter__c
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
                if (!serviceAppointment.HOT_IsEmployedInterpreter__c) {
                    String targetPageRef = getTargetPageRefInterpreter('interested', serviceAppointment.Id);
                    notification.setTargetPageRef(targetPageRef);
                }
                //String targetPageRef = getTargetPageRefInterpreter('interested', getHARs(serviceAppointment.Id));
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(serviceAppointment.Id);

                HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c =
                        serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy') +
                        ' - ' +
                        'Tatt av oppdraget';
                    newNotification.HOT_NotificationText__c =
                        'Du er tatt av oppdraget ' +
                        serviceAppointment.AppointmentNumber +
                        ' som skulle starte ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm');
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'noServiceAppointment';

                    notificationList.add(newNotification);
                }
            } else {
                saSMS.add(serviceAppointment.Id);
                HOT_Notification__c newNotification = new HOT_Notification__c();
                Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                newNotification.HOT_Account__c = account;
                newNotification.HOT_NotificationChannel__c = 'SMS';
                newNotification.HOT_Subject__c = 'INFO Du er tatt av oppdraget ' + serviceAppointment.AppointmentNumber;
                newNotification.HOT_NotificationText__c =
                    'Dato: ' +
                    serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                    ' - ' +
                    serviceAppointment.DueDate?.format('HH:mm') +
                    '.\n';
                newNotification.HOT_NotificationText__c +=
                    'For mer informasjon, se tolkebestilling.nav.no.\n' +
                    'Du kan ikke svare på denne meldingen.\n' +
                    'Mvh tolketjenesten i NAV';
                newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                newNotification.HOT_RelatedObjectType__c = 'noServiceAppointment';

                notificationList.add(newNotification);
            }
        }
        if (saSMS.size() > 0) {
            HOT_ReminderSMSService.sendSMSToInterpreterOnResourceChanged(saSMS);
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public static void screenInterpreterChanged(
        CustomNotificationType notificationType,
        Set<Id> saIds,
        Set<String> recipients,
        String isScreenInterpreterString
    ) {
        Set<Id> saSMS = new Set<Id>();
        List<ServiceAppointment> saList = [
            SELECT
                AppointmentNumber,
                EarliestStartTime,
                DueDate,
                HOT_AssignedResourceId__c,
                HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Id IN :saIds AND HOT_ServiceResource__r.HOT_NotificationChannel__c != NULL
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<Id, Id> userIdToAccountMap = new Map<Id, Id>();
        Set<Id> asUserIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : saList) {
            asUserIds.add(serviceAppointment.HOT_AssignedResourceId__c);
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE Id IN :asUserIds];
        for (User user : users) {
            userIdToAccountMap.put(user.Id, user.AccountId);
        }

        for (ServiceAppointment serviceAppointment : saList) {
            if (
                serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push') ||
                serviceAppointment.HOT_IsEmployedInterpreter__c
            ) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(
                    serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        'endret til ' +
                        isScreenInterpreterString
                );
                notification.setBody(
                    'Oppdraget ' +
                        serviceAppointment.AppointmentNumber +
                        ', ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        ' ble endret til ' +
                        isScreenInterpreterString
                );
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(serviceAppointment.Id);

                HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) serviceAppointment);
                //creating notification object
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c =
                        serviceAppointment.AppointmentNumber +
                        ' - ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        'endret til ' +
                        isScreenInterpreterString;
                    newNotification.HOT_NotificationText__c =
                        'Oppdraget ' +
                        serviceAppointment.AppointmentNumber +
                        ', ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        ' ble endret til ' +
                        isScreenInterpreterString;
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            } else {
                saSMS.add(serviceAppointment.Id);
                if (userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    saSMS.add(serviceAppointment.Id);
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = userIdToAccountMap.get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'SMS';
                    newNotification.HOT_Subject__c =
                        'INFO\n' +
                        serviceAppointment.AppointmentNumber +
                        ' ' +
                        formatTimePeriod(serviceAppointment.EarliestStartTime, serviceAppointment.DueDate) +
                        ' er endret';
                    newNotification.HOT_NotificationText__c =
                        'For mer informasjon, se tolkebestilling.nav.no.\n' +
                        'Du kan ikke svare på denne meldingen.\n' +
                        'Mvh tolketjenesten i NAV';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            }
        }
        if (saSMS.size() > 0) {
            HOT_ReminderSMSService.sendSMSToInterpreterOnScreenInterpretation(saSMS);
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }
    public static String formatTimePeriod(Datetime startDate, Datetime endDate) {
        String timePeriod =
            startDate.date().format() +
            '\nKlokkeslett: ' +
            (startDate.hour() < 10 ? '0' + String.valueOf(startDate.hour()) : String.valueOf(startDate.hour())) +
            '.' +
            (startDate.minute() < 10 ? '0' + String.valueOf(startDate.minute()) : String.valueOf(startDate.minute())) +
            ' - ' +
            (endDate.hour() < 10 ? '0' + String.valueOf(endDate.hour()) : String.valueOf(endDate.hour())) +
            '.' +
            (endDate.minute() < 10 ? '0' + String.valueOf(endDate.minute()) : String.valueOf(endDate.minute()));

        return timePeriod;
    }

    public static void notiyUserOnStatusChange(ServiceAppointment sa) {
        List<Id> accountIds = new List<Id>();
        Boolean isPerson = false;

        accountIds.add(sa.AccountId);

        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];

        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }

        // Needed to get latest SR and status I guess
        ServiceAppointment updatedSA = [
            SELECT HOT_ServiceResource__r.Name, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];

        List<WorkOrder> workordersList = [
            SELECT
                Id,
                StartDate,
                EndDate,
                AccountId,
                HOT_Interpreters__c,
                HOT_Request__r.IsNotNotifyAccount__c,
                Account.CRM_Person__r.HOT_NotificationChannel__c,
                Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c
            FROM WorkOrder
            WHERE
                Id = :updatedSA.HOT_WorkOrderLineItem__r.WorkOrderId
                AND Account.CRM_Person__r.HOT_NotificationChannel__c != NULL
                AND Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE
        ];

        if (!workordersList.isEmpty()) {
            for (WorkOrder wo : workordersList) {
                isPerson = wo.Account.CRM_Person__c != null ? true : false;
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(wo.AccountId) != null && !wo.HOT_Request__r.IsNotNotifyAccount__c) {
                    recipients.add(userIdByAccountId.get(wo.AccountId));
                }
                if (recipients.size() != 0 && isPerson) {
                    if (wo.Account.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) {
                        HOT_UserNotificationService.statusChangeNotification(
                            getCustomNotificationType('HOT_NotifyUser'),
                            wo,
                            updatedSA,
                            recipients
                        );
                    }
                }
            }
        }
    }
    public static void notifyUserOnChangedResource(ServiceAppointment sa) {
        List<Id> accountIds = new List<Id>();

        ServiceAppointment updatedSA = [
            SELECT HOT_WorkOrderLineItem__r.WorkOrderId, HOT_Request__r.Orderer__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];

        accountIds.add(updatedSA.HOT_Request__r.Orderer__c);

        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];

        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }

        List<WorkOrder> workordersList = [
            SELECT
                Id,
                Status,
                EndDate,
                StartDate,
                AccountId,
                HOT_Interpreters__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c,
                HOT_Request__r.Orderer__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c
            FROM WorkOrder
            WHERE
                Id = :updatedSA.HOT_WorkOrderLineItem__r.WorkOrderId
                AND HOT_Request__r.Orderer__c != NULL
                AND HOT_Request__r.Orderer__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE
                AND HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c = TRUE
        ];

        Map<Id, String> interpreterNames = HOT_ReminderSMSService.interpreterNamesByWorkOrderIds(workordersList);
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        if (!workordersList.isEmpty()) {
            for (WorkOrder wo : workordersList) {
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(wo.HOT_Request__r.Orderer__c) != null) {
                    recipients.add(userIdByAccountId.get(wo.HOT_Request__r.Orderer__c));
                }
                if (recipients.size() != 0 && wo.Status == 'Dispatched') {
                    if (wo.HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) {
                        HOT_UserNotificationService.interpreterChangeNotification(
                            getCustomNotificationType('HOT_NotifyUser'),
                            wo,
                            interpreterNames.get(wo.Id),
                            recipients
                        );
                        //creating notification object
                        HOT_Notification__c newNotification = new HOT_Notification__c();
                        newNotification.HOT_Account__c = wo.HOT_Request__r.Orderer__c;
                        newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                        newNotification.HOT_Subject__c = 'Endring av tolk';
                        String text =
                            'Tolk på din bestilling er endret. \nTolk er: ' +
                            interpreterNames.get(wo.Id) +
                            '\nDato: ' +
                            wo.StartDate?.format('dd.MM.yyyy', 'Europe/Oslo') +
                            ', kl: ' +
                            wo.StartDate?.format('HH:mm', 'Europe/Oslo') +
                            ' - ' +
                            wo.EndDate?.format('HH:mm', 'Europe/Oslo') +
                            '.';
                        if (text.length() > 250) {
                            newNotification.HOT_NotificationText__c = text.substring(0, 250) + ' ...';
                        } else {
                            newNotification.HOT_NotificationText__c = text;
                        }
                        newNotification.HOT_RelatedObject__c = wo.Id;
                        newNotification.HOT_RelatedObjectType__c = 'workOrder';

                        notificationList.add(newNotification);
                    } else {
                        Set<Id> workOrderIds = new Set<Id>();
                        workOrderIds.add(wo.Id);
                        HOT_ReminderSMSService.sendSMSOnInterpreterChange(workOrderIds, interpreterNames.get(wo.Id));
                    }
                }
                //inserting notifications
                try {
                    HOT_NotificationCentreController.createNotification(notificationList);
                } catch (Exception e) {
                    LoggerUtility logger = new LoggerUtility();
                    logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                    logger.publish();
                }
            }
        }
    }
    public static void notifyInterpretersOnChangedResource(ServiceAppointment sa) {
        ServiceAppointment getServiceAppointment = [
            SELECT
                HOT_WorkOrderLineItem__r.WorkOrderId,
                HOT_ServiceResource__r.Name,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c,
                SchedStartTime,
                SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];

        List<ServiceAppointment> updatedSA = [
            SELECT
                HOT_WorkOrderLineItem__r.WorkOrderId,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId = :getServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
                AND Id != :sa.Id
                AND Status = 'Dispatched'
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Set<String> freelanceInterpreterRecipients = new Set<String>();
        Set<String> employeeInterpreterRecipients = new Set<String>();
        Set<Id> serviceResourcesIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : updatedSA) {
            if (serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push')) {
                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c) {
                    employeeInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);
                } else {
                    freelanceInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);
                }
                if (
                    serviceAppointment.HOT_ServiceResource__r.AccountId != null &&
                    !serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c
                ) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c = 'Endring av medtolk';
                    String text =
                        'Medtolk på et oppdrag du er tildelt er blitt endret. \nNy tolk er: ' +
                        getServiceAppointment.HOT_ServiceResource__r.Name +
                        '.\nDato: ' +
                        getServiceAppointment.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        getServiceAppointment.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        getServiceAppointment.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
                        '.';
                    if (text.length() > 250) {
                        newNotification.HOT_NotificationText__c = text.substring(0, 250) + ' ...';
                    } else {
                        newNotification.HOT_NotificationText__c = text;
                    }
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
            } else {
                serviceResourcesIds.add(serviceAppointment.HOT_ServiceResource__r.Id);
                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c == true) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    if (serviceAppointment.HOT_ServiceResource__r.AccountId != null) {
                        newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                        newNotification.HOT_NotificationChannel__c = 'SMS';
                        newNotification.HOT_Subject__c = 'Endring av medtolk';
                        String text = 'INFO\nMedtolk på et oppdrag du er tildelt er blitt endret. \nNy tolk er:\n';
                        text += getServiceAppointment.HOT_ServiceResource__r.Name;
                        text +=
                            '.\nDato: ' +
                            HOT_ReminderSMSService.formatTimePeriod(
                                getServiceAppointment.SchedStartTime,
                                getServiceAppointment.SchedEndTime
                            );
                        text += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
                        text += '\nMvh tolketjenesten i NAV';
                        if (text.length() > 250) {
                            newNotification.HOT_NotificationText__c = text.substring(0, 250) + ' ...';
                        } else {
                            newNotification.HOT_NotificationText__c = text;
                        }
                        newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                        newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                        notificationList.add(newNotification);
                    }
                }
            }
        }
        if (!employeeInterpreterRecipients.isEmpty()) {
            HOT_UserNotificationService.coInterpreterChangeNotification(
                getCustomNotificationType('HOT_NotifyInterpreter'),
                sa,
                getServiceAppointment.HOT_ServiceResource__r.Name,
                employeeInterpreterRecipients
            );
        }
        if (!freelanceInterpreterRecipients.isEmpty()) {
            HOT_UserNotificationService.coInterpreterChangeNotification(
                getCustomNotificationType('HOT_NotifyUser'),
                sa,
                getServiceAppointment.HOT_ServiceResource__r.Name,
                freelanceInterpreterRecipients
            );
        }
        if (!serviceResourcesIds.isEmpty()) {
            String startEndString = HOT_ReminderSMSService.formatTimePeriod(
                getServiceAppointment.SchedStartTime,
                getServiceAppointment.SchedEndTime
            );
            HOT_ReminderSMSService.sendSMSOnCoInterpreterChange(
                serviceResourcesIds,
                startEndString,
                getServiceAppointment.HOT_ServiceResource__r.Name
            );
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public static CustomNotificationType getCustomNotificationType(String devName) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = :devName
        ];
        return notificationType;
    }

    public static String getTargetPageRefInterpreter(String targetList, Id targetId) {
        String pageRef =
            '{type: "comm__namedPage",attributes: {pageName: "mine-oppdrag"}, state: {from: "mine-varsler", list: "' +
            targetList +
            '", id: "' +
            targetId +
            '"}}';
        return pageRef;
    }
    public static String getTargetPageRefInterpreterOnChanged(String targetList, Id targetId) {
        String pageRef =
            '{type: "comm__namedPage",attributes: {pageName: "mine-oppdrag"}, state: {list: "' +
            targetList +
            '", id: "' +
            targetId +
            '"}}';
        return pageRef;
    }
}
