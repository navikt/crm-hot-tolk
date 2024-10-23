public without sharing class HOT_ServiceAppointmentNotification {
    Map<String,CustomNotificationType> customNotificationTypeByName;
    List<ServiceAppointment> sa;
    List<ServiceAppointment> oldSaMap;
    Map<Id,ServiceAppointment> updatedSAMap;
    Map<Id,Id> accountIdByUSerIdMap;
    Map<Id,Id> userIdByAccountIdMap;
    Map<Id,WorkOrder> workOrderMap;
    Map<Id, Map<Id,ServiceAppointment>> serviceAppointmentByWorkOrderIdMap;
    Map<Id,String> interpreterNamesByWorkOrderIdMap;
    Map<Id,ServiceResource> serviceResourceMap;
    
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    public static void resourceServiceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        HOT_ServiceAppointmentNotification sAN = new HOT_ServiceAppointmentNotification(serviceAppointments, (Map<Id,ServiceAppointment>)triggerOldMap);

        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            // Varsel ved tildelt tolk eller udekket + Varsel ved medtolk lagt til på flertolksoppdrag
            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                Set<String> interpreterRecipients = new Set<String>{ serviceAppointment.HOT_AssignedResourceId__c };
                saN.resourceAdded(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'),  serviceAppointment.Id, interpreterRecipients);
                saN.notifyInterpretersOnCoInterpreterAdded(serviceAppointment);
            }

            // Varsel ved endring av tolk
            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                Set<String> interpreterRecipients = new Set<String>{ serviceAppointment.HOT_AssignedResourceId__c };
                saN.resourceAdded(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'), serviceAppointment.Id, interpreterRecipients);

                saN.notifyUserOnChangedResource(serviceAppointment);
                saN.notifyInterpretersOnChangedResource(serviceAppointment);
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
                    saN.canceledByUser(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'), serviceAppointment, oldServiceAppointment.HOT_ServiceResource__c, recipients);
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
                    saN.timeChanged(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'), serviceAppointment.Id, recipients);
                }

                // Varsel ved endring av adresse
                if (
                    serviceAppointment.HOT_AddressFormated__c != oldServiceAppointment.HOT_AddressFormated__c &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                    serviceAppointment.Status != 'Scheduled'
                ) {
                    Set<Id> saIds = new Set<Id>{ serviceAppointment.Id };
                    addressChanged(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'), saIds, recipients);
                }

                // Varsel ved fjerning av tolk + varsel til medtolk av tolken er tatt av
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
                    resourceChanged(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'), saIds, recipients);
                    notifyInterpretersOnCoInterpreterRemoved(serviceAppointment);
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
                    screenInterpreterChanged(saN.getCustomNotificationTypeByName('HOT_Service_Appointment_Changed'), saIds, recipients, isScreenInterpreterString);
                }
            }
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
        }
    }

    public static void dispatcherServiceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        HOT_ServiceAppointmentNotification sAN = new HOT_ServiceAppointmentNotification(serviceAppointments, (Map<Id,ServiceAppointment>)triggerOldMap);
        
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
                resourceCanceled(saN.getCustomNotificationTypeByName('HOT_NotifyDispatcher'), serviceAppointment, recipients);
            }

            // Varsel ved avlyst på vegne av bruker
            if (serviceAppointment.Status == 'Canceled' && oldServiceAppointment.Status != 'Canceled') {
                saN.canceledByUser(saN.getCustomNotificationTypeByName('HOT_NotifyDispatcher'), serviceAppointment, oldServiceAppointment.HOT_ServiceResource__c, recipients);
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

    public void canceledByUser(
        CustomNotificationType notificationType,
        ServiceAppointment serviceAppointment,
        Id srId,
        Set<String> recipients
    ) {
        ServiceResource serviceResource = this.getServiceResourceMap().get(srId);
        if(serviceResource == null){
            return;
        }
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
            //creating notification object
            if (serviceResource.AccountId != null) {
                HOT_Notification__c newNotification = new HOT_Notification__c();
                newNotification.HOT_Account__c = serviceResource.AccountId;
                newNotification.HOT_NotificationChannel__c = 'SMS';
                newNotification.HOT_Subject__c =
                    'INFO ' +
                    serviceAppointment.AppointmentNumber +
                    ' ' +
                    serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                    ' - ' +
                    serviceAppointment.DueDate?.format('HH:mm') +
                    ' er avlyst.';
                newNotification.HOT_NotificationText__c =
                    'For mer informasjon, se tolkebestilling.nav.no.\n' +
                    'Du kan ikke svare på denne meldingen.\n' +
                    'Mvh tolketjenesten i Nav';
                newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                newNotification.HOT_RelatedObjectType__c = 'noServiceAppointment';

                if (newNotification.HOT_Account__c != null) {
                    notificationList.add(newNotification);
                }
            }
            HOT_ReminderSMSService.sendSMSToInterpreterOnCanceledByUser(new Set<Id>{serviceAppointment.Id}, new Set<Id>{srId});
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
        }
    }

    public void timeChanged(CustomNotificationType notificationType, Id saId, Set<String> recipients) {
        ServiceAppointment serviceAppointment = this.getUpdatedSAMap().get(saId);
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();


        if(serviceAppointment?.HOT_ServiceResource__r?.HOT_NotificationChannel__c != null){
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
                if (this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c);
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
                //creating notification object
                if (this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c);
                    newNotification.HOT_Account__c = account;
                    newNotification.HOT_NotificationChannel__c = 'SMS';
                    newNotification.HOT_Subject__c =
                        'INFO ' +
                        serviceAppointment.AppointmentNumber +
                        ' har endret tidspunkt.';
                    newNotification.HOT_NotificationText__c =
                        'Ny tid er: ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        '\nFor mer informasjon, se tolkebestilling.nav.no.\n' +
                        'Du kan ikke svare på denne meldingen.\n' +
                        'Mvh tolketjenesten i Nav';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
                HOT_ReminderSMSService.sendSMSToInterpreterOnTimeChanged(new Set<Id>{serviceAppointment.Id});
            }
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
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
                        serviceAppointment.AppointmentNumber +
                        ' ' +
                        serviceAppointment.EarliestStartTime?.format('d.M.yyyy HH:mm') +
                        ' - ' +
                        serviceAppointment.DueDate?.format('HH:mm') +
                        ' har endret adresse.';
                    newNotification.HOT_NotificationText__c =
                        'For mer informasjon, se tolkebestilling.nav.no.\n' +
                        'Du kan ikke svare på denne meldingen.\n' +
                        'Mvh tolketjenesten i Nav';
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
            handleException(e);
        }
    }

    public void resourceAdded(CustomNotificationType notificationType, Id saId, Set<String> recipients) {
        Set<Id> saSMS = new Set<Id>();
        ServiceAppointment serviceAppointment = this.getUpdatedSAMap().get(saId);
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        if (serviceAppointment?.HOT_ServiceResource__r?.HOT_NotificationChannel__c != null) {
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
                if (this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c);
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
                //creating notification object
                if (this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c) != null) {
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    Id account = this.getAccountIdByUserIdMap().get(serviceAppointment.HOT_AssignedResourceId__c);
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
                        'Mvh tolketjenesten i Nav';
                    newNotification.HOT_RelatedObject__c = serviceAppointment.Id;
                    newNotification.HOT_RelatedObjectType__c = 'serviceAppointment';

                    notificationList.add(newNotification);
                }
                HOT_ReminderSMSService.sendSMSToInterpreterOnAddedOrChanged(new Set<Id>{serviceAppointment.Id});
            }
        }
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
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
                    'Mvh tolketjenesten i Nav';
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
            handleException(e);
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
                        'Mvh tolketjenesten i Nav';
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
            handleException(e);
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

    public void notifyUserOnChangedResource(ServiceAppointment sa) {
        List<Id> accountIds = new List<Id>();

        ServiceAppointment updatedSA = this.getUpdatedSAMap().get(sa.Id);

        WorkOrder wo = this.getWorkOrderMap().get(updatedSA.HOT_WorkOrderLineItem__r.WorkOrderId);
        if(wo == null){
            return;
        }
        //creating notification object list
        Set<String> recipients = new Set<String>();
        if (this.getUserIdByAccountIdMap().get(wo.HOT_Request__r.Orderer__c) != null) {
            recipients.add(this.getUserIdByAccountIdMap().get(wo.HOT_Request__r.Orderer__c));
        }
        if (recipients.size() != 0 && wo.Status == 'Dispatched') {
            if (wo.HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')) {
                HOT_UserNotificationService.interpreterChangeNotification(
                    getCustomNotificationType('HOT_NotifyUser'),
                    wo,
                    this.getinterpreterNamesByWorkOrderIdMap().get(wo.Id),
                    recipients
                );
                //creating notification object
                HOT_Notification__c newNotification = new HOT_Notification__c();
                newNotification.HOT_Account__c = wo.HOT_Request__r.Orderer__c;
                newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                newNotification.HOT_Subject__c = 'Endring av tolk';
                String text =
                    'Tolk på din bestilling er endret. \nTolk er: ' +
                    this.getinterpreterNamesByWorkOrderIdMap().get(wo.Id) +
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
                try {
                    HOT_NotificationCentreController.createNotification(new List<HOT_Notification__c>{newNotification});
                } catch (Exception e) {
                    handleException(e);
                }
            } else {
                HOT_ReminderSMSService.sendSMSOnInterpreterChange(new Set<Id>{wo.Id}, this.getinterpreterNamesByWorkOrderIdMap().get(wo.Id));
            }
        }          
    }
    public static void notifyInterpretersOnCoInterpreterRemoved(ServiceAppointment sa) {
        ServiceAppointment updatedSAWithInterpreterRemoved = [
            SELECT HOT_WorkOrderLineItem__r.WorkOrderId, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];

        List<ServiceAppointment> relatedServiceAppointments = [
            SELECT
                HOT_WorkOrderLineItem__r.WorkOrderId,
                AppointmentNumber,
                SchedStartTime,
                SchedEndTime,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId = :updatedSAWithInterpreterRemoved.HOT_WorkOrderLineItem__r.WorkOrderId
                AND Id != :sa.Id
                AND Status = 'Dispatched'
                AND HOT_IsImageInterpreter__c = FALSE
        ];

        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Set<Id> serviceResourcesIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : relatedServiceAppointments) {
            if (serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push')) {
                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c) {
                    Set<String> employeeInterpreterRecipients = new Set<String>();
                    employeeInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);

                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Medtolk tatt av oppdraget');
                    notification.setBody(
                        'En medtolk er tatt av oppdraget: ' +
                        serviceAppointment.AppointmentNumber +
                        '\nDato: ' +
                        updatedSAWithInterpreterRemoved.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        updatedSAWithInterpreterRemoved.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        updatedSAWithInterpreterRemoved.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
                        '.'
                    );
                    notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyInterpreter').Id);
                    notification.setTargetId(serviceAppointment.Id);

                    HOT_NotificationHandler.sendNotification(
                        notification,
                        employeeInterpreterRecipients,
                        (SObject) serviceAppointment
                    );
                } else {
                    Set<String> freelanceInterpreterRecipients = new Set<String>();
                    freelanceInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);
                    HOT_UserNotificationService.coInterpreterRemovedNotification(
                        getCustomNotificationType('HOT_NotifyUser'),
                        updatedSAWithInterpreterRemoved,
                        getTargetPageRefInterpreter('my', serviceAppointment.Id),
                        freelanceInterpreterRecipients,
                        serviceAppointment.AppointmentNumber
                    );
                }
                if (
                    serviceAppointment.HOT_ServiceResource__r.AccountId != null &&
                    !serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c
                ) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c =
                        'Medtolk tatt av oppdraget: ' + serviceAppointment.AppointmentNumber;
                    String text =
                        'En medtolk er tatt av oppdraget' +
                        '.\nDato: ' +
                        updatedSAWithInterpreterRemoved.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        updatedSAWithInterpreterRemoved.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        updatedSAWithInterpreterRemoved.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
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
                String startEndString = HOT_ReminderSMSService.formatTimePeriod(
                    updatedSAWithInterpreterRemoved.SchedStartTime,
                    updatedSAWithInterpreterRemoved.SchedEndTime
                );
                HOT_ReminderSMSService.sendSMSOnCoInterpreterRemoved(
                    serviceAppointment.HOT_ServiceResource__r.Id,
                    startEndString,
                    serviceAppointment.AppointmentNumber
                );

                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c == true) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    if (serviceAppointment.HOT_ServiceResource__r.AccountId != null) {
                        newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                        newNotification.HOT_NotificationChannel__c = 'SMS';
                        newNotification.HOT_Subject__c =
                            'Medtolk tatt av oppdraget. ' + serviceAppointment.AppointmentNumber;
                        String text = 'INFO\nEn medtolk er tatt av oppdraget\n';
                        text +=
                            '.\nDato: ' +
                            HOT_ReminderSMSService.formatTimePeriod(
                                updatedSAWithInterpreterRemoved.SchedStartTime,
                                updatedSAWithInterpreterRemoved.SchedEndTime
                            );
                        text += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
                        text += '\nMvh tolketjenesten i Nav';
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
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
        }
    }
    public void notifyInterpretersOnCoInterpreterAdded(ServiceAppointment sa) {
        ServiceAppointment updatedSAWithNewInterpreter = this.getUpdatedSAMap().get(sa.Id);

        List<ServiceAppointment> relatedServiceAppointments = this.getRelatedServiceAppointments(sa);

        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Set<Id> serviceResourcesIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : relatedServiceAppointments) {
            if (serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push')) {
                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c) {
                    Set<String> employeeInterpreterRecipients = new Set<String>();
                    employeeInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);

                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Ny medtolk ' + serviceAppointment.AppointmentNumber);
                    notification.setBody(
                        'Du har fått medtolk. \nTolk er: ' +
                        updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name +
                        '\nDato: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        updatedSAWithNewInterpreter.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
                        '.'
                    );
                    notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyInterpreter').Id);
                    notification.setTargetId(serviceAppointment.Id);

                    HOT_NotificationHandler.sendNotification(
                        notification,
                        employeeInterpreterRecipients,
                        (SObject) serviceAppointment
                    );
                } else {
                    Set<String> freelanceInterpreterRecipients = new Set<String>();
                    freelanceInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);
                    HOT_UserNotificationService.newCoInterpreterChangeNotification(
                        getCustomNotificationType('HOT_NotifyUser'),
                        updatedSAWithNewInterpreter,
                        getTargetPageRefInterpreter('my', serviceAppointment.Id),
                        updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name,
                        freelanceInterpreterRecipients,
                        serviceAppointment.AppointmentNumber
                    );
                }
                if (
                    serviceAppointment.HOT_ServiceResource__r.AccountId != null &&
                    !serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c
                ) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c = 'Ny medtolk ' + serviceAppointment.AppointmentNumber;
                    String text =
                        'Du har fått medtolk. \nTolk er: ' +
                        updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name +
                        '.\nDato: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        updatedSAWithNewInterpreter.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
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
                String startEndString = HOT_ReminderSMSService.formatTimePeriod(
                    updatedSAWithNewInterpreter.SchedStartTime,
                    updatedSAWithNewInterpreter.SchedEndTime
                );
                HOT_ReminderSMSService.sendSMSOnNewCoInterpreterChange(
                    serviceAppointment.HOT_ServiceResource__r.Id,
                    startEndString,
                    serviceAppointment.AppointmentNumber,
                    updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name
                );

                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c == true) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    if (serviceAppointment.HOT_ServiceResource__r.AccountId != null) {
                        newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                        newNotification.HOT_NotificationChannel__c = 'SMS';
                        newNotification.HOT_Subject__c = 'Ny medtolk ' + serviceAppointment.AppointmentNumber;
                        String text = 'INFO\nDu har fått medtolk. \nTolk er:\n';
                        text += updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name;
                        text +=
                            '.\nDato: ' +
                            HOT_ReminderSMSService.formatTimePeriod(
                                updatedSAWithNewInterpreter.SchedStartTime,
                                updatedSAWithNewInterpreter.SchedEndTime
                            );
                        text += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
                        text += '\nMvh tolketjenesten i Nav';
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

        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
        }
    }
    public void notifyInterpretersOnChangedResource(ServiceAppointment sa) {
        ServiceAppointment updatedSAWithNewInterpreter = this.getUpdatedSAMap().get(sa.Id);

        List<ServiceAppointment> relatedServiceAppointments = this.getRelatedServiceAppointments(sa);

        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Set<Id> serviceResourcesIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : relatedServiceAppointments) {
            if (serviceAppointment.HOT_ServiceResource__r.HOT_NotificationChannel__c.contains('Push')) {
                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c) {
                    Set<String> employeeInterpreterRecipients = new Set<String>();
                    employeeInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);

                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Endring av medtolk ' + serviceAppointment.AppointmentNumber);
                    notification.setBody(
                        'Medtolk på et oppdrag du er tildelt er blitt endret. \nNy tolk er: ' +
                        updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name +
                        '\nDato: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        updatedSAWithNewInterpreter.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
                        '.'
                    );
                    notification.setNotificationTypeId(this.getCustomNotificationTypeByName('HOT_NotifyInterpreter').Id);
                    notification.setTargetId(serviceAppointment.Id);

                    HOT_NotificationHandler.sendNotification(
                        notification,
                        employeeInterpreterRecipients,
                        (SObject) serviceAppointment
                    );
                } else {
                    Set<String> freelanceInterpreterRecipients = new Set<String>();
                    freelanceInterpreterRecipients.add(serviceAppointment.HOT_ServiceResource__r.RelatedRecordId);
                    HOT_UserNotificationService.coInterpreterChangeNotification(
                        this.getCustomNotificationTypeByName('HOT_NotifyUser'),
                        updatedSAWithNewInterpreter,
                        getTargetPageRefInterpreter('my', serviceAppointment.Id),
                        updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name,
                        freelanceInterpreterRecipients,
                        serviceAppointment.appointmentNumber
                    );
                }
                if (
                    serviceAppointment.HOT_ServiceResource__r.AccountId != null &&
                    !serviceAppointment.HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c
                ) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                    newNotification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    newNotification.HOT_Subject__c = 'Endring av medtolk ' + serviceAppointment.AppointmentNumber;
                    String text =
                        'Medtolk på et oppdrag du er tildelt er blitt endret.  \nNy tolk er: ' +
                        updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name +
                        '.\nDato: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                        ', kl: ' +
                        updatedSAWithNewInterpreter.SchedStartTime?.format('HH:mm', 'Europe/Oslo') +
                        ' - ' +
                        updatedSAWithNewInterpreter.SchedEndTime?.format('HH:mm', 'Europe/Oslo') +
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
                String startEndString = HOT_ReminderSMSService.formatTimePeriod(
                    updatedSAWithNewInterpreter.SchedStartTime,
                    updatedSAWithNewInterpreter.SchedEndTime
                );
                HOT_ReminderSMSService.sendSMSOnCoInterpreterChange(
                    serviceAppointment.HOT_ServiceResource__r.Id,
                    startEndString,
                    serviceAppointment.AppointmentNumber,
                    updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name
                );
                if (serviceAppointment.HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c == true) {
                    //creating notification object
                    HOT_Notification__c newNotification = new HOT_Notification__c();
                    if (serviceAppointment.HOT_ServiceResource__r.AccountId != null) {
                        newNotification.HOT_Account__c = serviceAppointment.HOT_ServiceResource__r.AccountId;
                        newNotification.HOT_NotificationChannel__c = 'SMS';
                        newNotification.HOT_Subject__c = 'Endring av medtolk ' + serviceAppointment.AppointmentNumber;
                        String text = 'INFO\nMedtolk på et oppdrag du er tildelt er blitt endret. \nNy tolk er:\n';
                        text += updatedSAWithNewInterpreter.HOT_ServiceResource__r.Name;
                        text +=
                            '.\nDato: ' +
                            HOT_ReminderSMSService.formatTimePeriod(
                                updatedSAWithNewInterpreter.SchedStartTime,
                                updatedSAWithNewInterpreter.SchedEndTime
                            );
                        text += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
                        text += '\nMvh tolketjenesten i Nav';
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
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            handleException(e);
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

    private static Map<String,CustomNotificationType> getCustomNotificationTypeByNameMap(){
        Map<String, CustomNotificationType> cntMap = new Map<String, CustomNotificationType>();
        List<CustomNotificationType> cntList = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
        ];
        for(CustomNotificationType cnt : cntList){
            cntMap.put(cnt.DeveloperName,cnt);
        }
        return cntMap;
    }
    
    public CustomNotificationType getCustomNotificationTypeByName(String Name){
        if(this.customNotificationTypeByName == null){
            this.customNotificationTypeByName = HOT_ServiceAppointmentNotification.getCustomNotificationTypeByNameMap();
        }
        return this.customNotificationTypeByName.get(Name);
    }
    private static Map<Id,ServiceAppointment> getUpdatedServiceAppointments(List<ServiceAppointment> serviceAppointments){
        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>([
            SELECT
                Id,
                AccountId,
                HOT_AssignedResourceId__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_WorkOrderLineItem__r.WorkOrderId,
                HOT_ServiceResource__r.Name,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.AccountId,
                HOT_Request__r.Orderer__c,
                AppointmentNumber,
                EarliestStartTime,
                HOT_IsEmployedInterpreter__c,
                DueDate,
                SchedStartTime,
                SchedEndTime
            FROM ServiceAppointment
            WHERE 
                Id IN :serviceAppointments
        ]);
        return saMap; 
    }
    private Map<Id, ServiceAppointment> getUpdatedSAMap() {
        if(this.updatedSAMap == null){
            this.updatedSAMap = HOT_ServiceAppointmentNotification.getUpdatedServiceAppointments(this.sa);
        }
        return this.updatedSAMap;
    }
    private Map<Id,ServiceAppointment> getUpdatedSAMapById(Set<Id> saIds){
        Map<Id, ServiceAppointment> mapToReturn = new Map<Id, ServiceAppointment>();

        for(ServiceAppointment sa : this.getUpdatedSAMap().values()){
            if(saIds.contains(sa.Id)){
                mapToReturn.put(sa.Id, sa);
            }
        }
        return mapToReturn;
    }
    private static List<User> getUserByAccountIds(Set<Id> accountIds){
        List<User> users = [
            SELECT Id, AccountId
            FROM User
            WHERE AccountId IN :accountIds
        ];
        return users;
    }
    private Map<Id,Id> getUserIdByAccountIdMap(){
        if(this.userIdByAccountIdMap == null){
            Set<Id> accountIds = new Set<Id>();
            for(ServiceAppointment sa : this.getUpdatedSAMap().values()){
                accountIds.add(sa.HOT_Request__r.Orderer__c);
            }
            Map<Id,Id> userByAccountMap = new Map<Id,Id>();
            for(User u : HOT_ServiceAppointmentNotification.getUserByAccountIds(accountIds)){
                userByAccountMap.put(u.AccountId, u.Id);
            }
            this.userIdByAccountIdMap = userByAccountMap;
        }
        return this.userIdByAccountIdMap;
    }
    private static List<User> getUsersByUserIds(Set<Id> userIds){
        List<User> users = [SELECT Id, AccountId FROM User WHERE Id IN: userIds];
        return users;
    }
    private Map<Id,Id> getAccountIdByUserIdMap(){
        if(this.accountIdByUserIdMap == null){
            Set<Id> userIds = new Set<Id>();
            for(ServiceAppointment sa : this.getUpdatedSAMap().values()){
                if(sa.HOT_AssignedResourceId__c != null){
                    userIds.add(sa.HOT_AssignedResourceId__c);
                }
            }
            Map<Id,Id> accountByUserMap = new Map<Id,Id>();
            for(User u : HOT_ServiceAppointmentNotification.getUsersByUserIds(userIds)){
                accountByUserMap.put(u.Id, u.AccountId);
            }
            this.accountIdByUserIdMap = accountByUserMap;
        }
        return this.accountIdByUSerIdMap;
    }
    private Map<Id,Id> getAccountIdByUserIdMap(Set<Id> userIds){
        Map<Id,Id> mapToReturn = new Map<Id,Id>();
        for(Id uId : userIds){
            mapToReturn.put(uId, this.getAccountIdByUserIdMap().get(uId));
        }
        return mapToReturn;
    }
    private static List<ServiceAppointment> getRelatedServiceAppointments(Set<Id> workOrderIds){
        return [
            SELECT
                HOT_WorkOrderLineItem__r.WorkOrderId,
                SchedStartTime,
                SchedEndTime,
                AppointmentNumber,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_IsFreelanceInterpreter__c,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_ServiceResource__r.RelatedRecordId,
                HOT_ServiceResource__r.Id
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds
                AND Status = 'Dispatched'
                AND HOT_IsImageInterpreter__c = FALSE
        ]; 
    }
    private Map<Id,Map<Id,ServiceAppointment>> getServiceAppointmentByWorkOrderIdMap(){
        if(this.serviceAppointmentByWorkOrderIdMap == null){
            Set<Id> workOrderIds = new Set<Id>();
            for (ServiceAppointment sa : this.getUpdatedSAMap().values()) {
                if(workOrderIds != null){
                    workOrderIds.add(sa.HOT_WorkOrderLineItem__r.WorkOrderId);
                }
            }
            this.serviceAppointmentByWorkOrderIdMap = new Map<Id,Map<Id,ServiceAppointment>>();
            for(ServiceAppointment sa : HOT_ServiceAppointmentNotification.getRelatedServiceAppointments(workOrderIds)){
                if(this.serviceAppointmentByWorkOrderIdMap.containsKey(sa.HOT_WorkOrderLineItem__r.WorkOrderId)){
                    this.serviceAppointmentByWorkOrderIdMap.get(sa.HOT_WorkOrderLineItem__r.WorkOrderId).put(sa.Id,sa);
                } else {
                    this.serviceAppointmentByWorkOrderIdMap.put(
                         sa.HOT_WorkOrderLineItem__r.WorkOrderId,
                        new Map<Id, ServiceAppointment>{ sa.Id => sa }
                    );
                }
            }
        }
        return this.serviceAppointmentByWorkOrderIdMap;
    }
    private List<ServiceAppointment> getRelatedServiceAppointments(ServiceAppointment sa){
        if(sa.HOT_WorkOrderLineItem__r.WorkOrderId == null){
            return new List<ServiceAppointment>();
        }
        Map<Id,ServiceAppointment> relatedServiceAppointmentMap = new Map<Id, ServiceAppointment>();
        relatedServiceAppointmentMap.putAll(
            this.getServiceAppointmentByWorkOrderIdMap().get(sa.HOT_WorkOrderLineItem__r.WorkOrderId)
        );
        relatedServiceAppointmentMap.remove(sa.Id);
        return relatedServiceAppointmentMap.values();
    }
    private static List<WorkOrder> getWorkOrders(Set<Id> workOrderIds){
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
                Id IN :workOrderIds
                AND HOT_Request__r.Orderer__c != NULL
                AND HOT_Request__r.Orderer__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE
                AND HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c = TRUE
        ];
        return workordersList;
    }
    private Map<Id,WorkOrder> getWorkOrderMap(){
        if(this.workOrderMap == null){
            Set<Id> workOrderIds = new Set<Id>();
            for(ServiceAppointment sa : this.getUpdatedSaMap().values()){
                workOrderIds.add(sa.HOT_WorkOrderLineItem__r.WorkOrderId);
            }
            this.workOrderMap = new Map<Id,WorkOrder>(HOT_ServiceAppointmentNotification.getWorkOrders(workOrderIds));
        }
        return this.workOrderMap;
    }
    private Map<Id, String> getinterpreterNamesByWorkOrderIdMap(){
        if(this.interpreterNamesByWorkOrderIdMap == null){
            this.interpreterNamesByWorkOrderIdMap = HOT_ReminderSMSService.interpreterNamesByWorkOrderIds(this.getWorkOrderMap().values());
        }
        return this.interpreterNamesByWorkOrderIdMap;
    }
    private static List<ServiceResource> getServiceResourceList(Set<Id> srIds){
        List<ServiceResource> serviceResourceList = [
            SELECT HOT_NotificationChannel__c, AccountId
            FROM ServiceResource
            WHERE Id IN :srIds AND HOT_NotificationChannel__c != NULL
        ];
        return serviceResourceList;
    }
    public Map<Id,ServiceResource> getServiceResourceMap(){
        if(this.serviceResourceMap == null){
            Set<Id> srIds = new Set<Id>();
            for(ServiceAppointment sa : this.getUpdatedSaMap().values()){
                if(sa.HOT_ServiceResource__c != null){
                    srIds.add(sa.HOT_ServiceResource__c);
                }
            }
            this.serviceResourceMap = new Map<Id, ServiceResource>(HOT_ServiceAppointmentNotification.getServiceResourceList(srIds));
        }
        return this.serviceResourceMap;
    }

    public HOT_ServiceAppointmentNotification(List<ServiceAppointment> saList, Map<Id,ServiceAppointment> oldSaMapt){
        this.sa = saList;
        this.oldSaMap = oldSaMap;
    }
    @TestVisible
    private HOT_ServiceAppointmentNotification(List<ServiceAppointment> saList){
        this.sa = saList;
    }
}
