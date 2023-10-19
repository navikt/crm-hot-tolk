public without sharing class HOT_ReminderSMSService {
    public static void reminderSMS(List<WorkOrder> workOrderList) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(workOrderList);
        Map<Id, String> interpreterNames = interpreterNamesByWorkOrderIds(workOrderList);
        List<SMS__c> smsList = new List<SMS__c>();
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        for (WorkOrder workOrder : workOrders.values()) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = '24 Hour Scheduled Reminder';
            sms.Account__c = workOrder.AccountId;
            sms.WorkOrder__c = workOrder.Id;
            sms.Recipient__c = workOrder.Account.CRM_Person__r.INT_KrrMobilePhone__c;
            sms.Message__c = constructReminderMessage(workOrder, interpreterNames.get(workOrder.Id));
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
                workOrder.HOT_IsReminderSMSSendt__c = true;
                //creating notification object
                HOT_Notification__c notification = new HOT_Notification__c();
                notification.HOT_Account__c = workOrder.AccountId;
                notification.HOT_NotificationChannel__c = 'SMS';
                notification.HOT_Subject__c = 'Påminnelse om tolkebestilling';
                notification.HOT_NotificationText__c =
                    'PÅMINNELSE\nVi minner om tolkebestilling:\n' +
                    'Dato: ' +
                    formatTimePeriod(workOrder.StartDate, workOrder.EndDate) +
                    '\n' +
                    'Tolk er: ' +
                    interpreterNames.get(workOrder.Id);
                notification.HOT_RelatedObject__c = workOrder.Id;
                notification.HOT_RelatedObjectType__c = 'workOrder';

                notificationList.add(notification);
            }
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(workOrders.values());
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public static void notifyUserOnOrderSMS(List<HOT_Request__c> requestList) {
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(requestList);
        List<SMS__c> smsList = new List<SMS__c>();

        for (HOT_Request__c request : requests.values()) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Orderer On Status Update';
            sms.Account__c = request.Account__c;
            sms.Recipient__c = request.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
            sms.Message__c = constructOnOrdererMessage(request);
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
                request.IsNotifyUserOnOrder__c = false;
                //creating notification object
                HOT_Notification__c notification = new HOT_Notification__c();
                notification.HOT_Account__c = request.Account__c;
                notification.HOT_NotificationChannel__c = 'SMS';
                notification.HOT_Subject__c = 'INFO\nDet er bestilt tolk til deg';
                String message = '';
                if (request.IsSerieoppdrag__c) {
                    message += ' i perioden: ' + request.SeriesPeriod__c;
                } else {
                    message += ':\nDato: ' + formatTimePeriod(request.StartTime__c, request.EndTime__c);
                }
                notification.HOT_NotificationText__c = message;
                if (request.IsSerieoppdrag__c) {
                    notification.HOT_RelatedObject__c = request.Id;
                    notification.HOT_RelatedObjectType__c = HOT_WorkOrderHandler.getWorkOrder(request).Id;
                } else {
                    notification.HOT_RelatedObject__c = HOT_WorkOrderHandler.getWorkOrder(request).Id;
                    notification.HOT_RelatedObjectType__c = 'workOrder';
                }

                notificationList.add(notification);
            }
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(requests.values());
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    private static Map<Id, List<ServiceAppointment>> dispatchedServiceAppointmentsByWorkOrderId(
        List<WorkOrder> workOrders
    ) {
        List<WorkOrderLineItem> workOrderLineItems = [
            SELECT
                Id,
                WorkOrderId,
                (
                    SELECT Id, HOT_ServiceResource__r.Name
                    FROM WorkOrderLineItem.HOT_ServiceAppointments__r
                    WHERE Status = 'Dispatched'
                )
            FROM WorkOrderLineItem
            WHERE WorkOrderId IN :workOrders
        ];
        Map<Id, List<ServiceAppointment>> dispatchedServiceAppointmentsByWorkOrderId = new Map<Id, List<ServiceAppointment>>();

        for (WorkOrderLineItem woli : workOrderLineItems) {
            if (dispatchedServiceAppointmentsByWorkOrderId.get(woli.WorkOrderId) == null) {
                dispatchedServiceAppointmentsByWorkOrderId.put(
                    woli.WorkOrderId,
                    new List<ServiceAppointment>(woli.HOT_ServiceAppointments__r)
                );
            } else {
                dispatchedServiceAppointmentsByWorkOrderId.get(woli.WorkOrderId)
                    .addAll(woli.HOT_ServiceAppointments__r);
            }
        }
        return dispatchedServiceAppointmentsByWorkOrderId;
    }

    public static Map<Id, String> interpreterNamesByWorkOrderIds(List<WorkOrder> workOrders) {
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = dispatchedServiceAppointmentsByWorkOrderId(
            workOrders
        );
        Map<Id, String> interpreterNamesByWorkOrderIds = new Map<Id, String>();

        for (WorkOrder workOrder : workOrders) {
            String interpreterNames = '';
            List<ServiceAppointment> serviceAppointents = serviceAppointmentsByWorkOrderId.get(workOrder.Id);
            if (serviceAppointents != null) {
                for (Integer i = 0; i < serviceAppointents.size(); i++) {
                    interpreterNames += serviceAppointents[i].HOT_ServiceResource__r.Name + ', ';
                }
                interpreterNames = interpreterNames.removeEnd(', ');
                interpreterNames += '. ';
            }
            interpreterNamesByWorkOrderIds.put(workOrder.Id, interpreterNames);
        }
        return interpreterNamesByWorkOrderIds;
    }

    private static String constructReminderMessage(WorkOrder workOrder, String interpreterNames) {
        String message = 'PÅMINNELSE\nVi minner om tolkebestilling:\n';
        message += 'Dato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate) + '\n';
        message += 'Tolk er: ';
        message += interpreterNames;
        message += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh tolketjenesten i NAV';
        return message;
    }

    public static void sendSMSToOrdererOnStatusUpdate(List<WorkOrder> workOrderList) {
        Map<Id, String> interpreterNames = interpreterNamesByWorkOrderIds(workOrderList);
        List<SMS__c> smsList = new List<SMS__c>();
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        for (WorkOrder workOrder : workOrderList) {
            String phoneNumber = getRecipient(workOrder);
            if (
                phoneNumber != null &&
                workOrder.StartDate > Datetime.now() &&
                workOrder.HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c == true &&
                (workOrder.Status == 'Dispatched' ||
                workOrder.Status == 'Cannot Complete')
            ) {
                SMS__c sms = new SMS__c();
                sms.Domain__c = 'HOT';
                sms.Type__c = 'Orderer On Status Update';
                sms.Account__c = workOrder.HOT_Request__r.Orderer__c;
                sms.WorkOrder__c = workOrder.Id;
                sms.Recipient__c = phoneNumber;
                sms.Message__c = constructStatusChangedMessage(workOrder, interpreterNames.get(workOrder.Id));
                smsList.add(sms);
                //creating notification object
                HOT_Notification__c notification = new HOT_Notification__c();
                notification.HOT_Account__c = workOrder.HOT_Request__r.Orderer__c;
                notification.HOT_NotificationChannel__c = 'SMS';
                notification.HOT_Subject__c = 'INFO\nStatus på din bestilling er:\n';
                if (workOrder.Status == 'Dispatched') {
                    notification.HOT_NotificationText__c =
                        'Du har fått tolk. Tolk er: ' +
                        interpreterNames.get(workOrder.Id) +
                        formatTimePeriod(workOrder.StartDate, workOrder.EndDate);
                } else if (workOrder.Status == 'Cannot Complete') {
                    notification.HOT_NotificationText__c =
                        'Ikke ledig tolk' +
                        '\nDato: ' +
                        formatTimePeriod(workOrder.StartDate, workOrder.EndDate);
                }
                notification.HOT_RelatedObject__c = workOrder.Id;
                notification.HOT_RelatedObjectType__c = 'workOrder';

                notificationList.add(notification);
            }
            workOrder.HOT_SendSMSNotificationOnStatusChanged__c = false;
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(workOrderList);
        //inserting notifications
        try {
            HOT_NotificationCentreController.createNotification(notificationList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    @Future
    public static void sendSMSOnNewMessage(Set<Id> threadIds) {
        List<SMS__c> smsList = new List<SMS__c>();
        List<Thread__c> threadList = [
            SELECT
                CRM_Account__c,
                CRM_Thread_Type__c,
                CRM_Account__r.CRM_Person__r.INT_KrrMobilePhone__c,
                CRM_Related_Object__c
            FROM Thread__c
            WHERE Id IN :threadIds
        ];

        for (Thread__c thread : threadList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Message';
            sms.Account__c = thread.CRM_Account__c;
            sms.Thread__c = thread.Id;
            sms.Recipient__c = getRecipientOnThread(thread);
            sms.Message__c = constructOnNewMessage();
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
    @Future
    public static void sendSMSOnNewMessageInterpreter(String userId, String threadId) {
        User user = [SELECT Id, AccountId FROM User WHERE Id = :userId];
        List<SMS__c> smsList = new List<SMS__c>();

        SMS__c sms = new SMS__c();
        sms.Domain__c = 'HOT';
        sms.Type__c = 'Message';
        sms.Account__c = user.AccountId;
        sms.Thread__c = threadId;
        sms.Recipient__c = getRecipientPhoneNumberInterpreter(userId);
        sms.Message__c = constructOnNewMessage();
        if (SMS.Recipient__c != null) {
            smsList.add(sms);
        }

        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSOnNewWantedSR(Set<Id> wantedIRIds) {
        List<SMS__c> smsList = new List<SMS__c>();
        List<HOT_InterestedResource__c> wantedIRList = [
            SELECT ServiceResource__r.Account.Id, ServiceResource__r.HOT_MobilePhone__c
            FROM HOT_InterestedResource__c
            WHERE Id IN :wantedIRIds
        ];
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        for (HOT_InterestedResource__c ir : wantedIRList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Message';
            sms.Account__c = ir.ServiceResource__r.Account.Id;
            sms.Recipient__c = ir.ServiceResource__r.HOT_MobilePhone__c;
            sms.Message__c = constructOnNewWantedSR();
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }

            //creating notification object
            HOT_Notification__c notification = new HOT_Notification__c();
            notification.HOT_Account__c = ir.ServiceResource__r.Account.Id;
            notification.HOT_NotificationChannel__c = 'SMS';
            notification.HOT_Subject__c = 'Du er ønsket til et oppdrag';
            notification.HOT_NotificationText__c = 'INFO\nDu er ønsket til et oppdrag.\n\n';
            notification.HOT_RelatedObject__c = ir.Id;
            notification.HOT_RelatedObjectType__c = 'wanted';

            notificationList.add(notification);
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
            //inserting notifications
            try {
                HOT_NotificationCentreController.createNotification(notificationList);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSOnInterpreterChange(Set<Id> workOrderIds, String interpreterName) {
        List<WorkOrder> workOrderList = [
            SELECT
                Id,
                AccountId,
                Status,
                StartDate,
                EndDate,
                HOT_Request__c,
                HOT_Interpreters__c,
                HOT_Request__r.Type__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                Account.CRM_Person__r.INT_KrrMobilePhone__c
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        for (WorkOrder wo : workOrderList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Orderer On Status Update';
            sms.Account__c = wo.HOT_Request__r.Orderer__c;
            sms.WorkOrder__c = wo.Id;
            sms.Recipient__c = getRecipient(wo);
            sms.Message__c = constructInterpreterChangedMessage(wo, interpreterName);
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
                //creating notification object
                HOT_Notification__c notification = new HOT_Notification__c();
                notification.HOT_Account__c = wo.HOT_Request__r.Orderer__c;
                notification.HOT_NotificationChannel__c = 'SMS';
                notification.HOT_Subject__c = 'INFO\nTolk på din bestilling er endret:\n';
                notification.HOT_NotificationText__c =
                    'INFO\nTolk på din bestilling er endret:\n' +
                    'Tolk er: ' +
                    wo.HOT_Interpreters__c +
                    '\nDato: ' +
                    formatTimePeriod(wo.StartDate, wo.EndDate);
                notification.HOT_RelatedObject__c = wo.Id;
                notification.HOT_RelatedObjectType__c = 'workOrder';

                notificationList.add(notification);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
            //inserting notifications
            try {
                HOT_NotificationCentreController.createNotification(notificationList);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSToInterpreterOnScreenInterpretation(Set<Id> saIds) {
        List<ServiceAppointment> saList = [
            SELECT
                Status,
                AppointmentNumber,
                HOT_ServiceResource__c,
                EarliestStartTime,
                DueDate,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_MobilePhone__c
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (ServiceAppointment sa : saList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Interpreter';
            sms.Account__c = sa.HOT_ServiceResource__r?.AccountId;
            sms.ServiceAppointment__c = sa.Id;
            sms.Recipient__c = sa.HOT_ServiceResource__r?.HOT_MobilePhone__c;
            sms.Message__c = constructMessageToInterpreter(sa, 'Screen');
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSToInterpreterOnTimeChanged(Set<Id> saIds) {
        List<ServiceAppointment> saList = [
            SELECT
                Status,
                AppointmentNumber,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_MobilePhone__c
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (ServiceAppointment sa : saList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Interpreter';
            sms.Account__c = sa.HOT_ServiceResource__r?.AccountId;
            sms.ServiceAppointment__c = sa.Id;
            sms.Recipient__c = sa.HOT_ServiceResource__r?.HOT_MobilePhone__c;
            sms.Message__c = constructMessageToInterpreter(sa, 'Time');
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSToInterpreterOnCanceledByUser(Set<Id> saIds, Set<Id> srIds) {
        List<ServiceAppointment> saList = [
            SELECT Status, AppointmentNumber, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];
        List<ServiceResource> srList = [SELECT AccountId, HOT_MobilePhone__c FROM ServiceResource WHERE Id IN :srIds];
        List<SMS__c> smsList = new List<SMS__c>();

        for (ServiceAppointment sa : saList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Interpreter';
            sms.Account__c = srList[0]?.AccountId;
            sms.ServiceAppointment__c = sa.Id;
            sms.Recipient__c = srList[0]?.HOT_MobilePhone__c;
            sms.Message__c = constructMessageToInterpreter(sa, 'CancelledByUser');
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSToInterpreterOnAddressChanged(Set<Id> saIds) {
        List<ServiceAppointment> saList = [
            SELECT
                Status,
                AppointmentNumber,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_MobilePhone__c
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (ServiceAppointment sa : saList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Interpreter';
            sms.Account__c = sa.HOT_ServiceResource__r?.AccountId;
            sms.ServiceAppointment__c = sa.Id;
            sms.Recipient__c = sa.HOT_ServiceResource__r?.HOT_MobilePhone__c;
            sms.Message__c = constructMessageToInterpreter(sa, 'Address');
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSToInterpreterOnAddedOrChanged(Set<Id> saIds) {
        List<ServiceAppointment> saList = [
            SELECT
                Status,
                AppointmentNumber,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_MobilePhone__c
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (ServiceAppointment sa : saList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Interpreter';
            sms.Account__c = sa.HOT_ServiceResource__r?.AccountId;
            sms.ServiceAppointment__c = sa.Id;
            sms.Recipient__c = sa.HOT_ServiceResource__r?.HOT_MobilePhone__c;
            sms.Message__c = constructMessageToInterpreter(sa, 'Dispatched');
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void sendSMSToInterpreterOnResourceChanged(Set<Id> saIds) {
        List<ServiceAppointment> saList = [
            SELECT
                Status,
                AppointmentNumber,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.AccountId,
                HOT_ServiceResource__r.HOT_MobilePhone__c
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (ServiceAppointment sa : saList) {
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = 'Interpreter';
            sms.Account__c = sa.HOT_ServiceResource__r?.AccountId;
            sms.ServiceAppointment__c = sa.Id;
            sms.Recipient__c = sa.HOT_ServiceResource__r?.HOT_MobilePhone__c;
            sms.Message__c = constructMessageToInterpreter(sa, 'Removed');
            if (SMS.Recipient__c != null) {
                smsList.add(sms);
            }
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
    public static String constructOnNewWantedSR() {
        String message = 'INFO\nDu er ønsket til et oppdrag.\n\n';
        message += 'For mer informasjon, se tolkebestilling.nav.no.\n';
        message += 'Du kan ikke svare på denne meldingen.\n';
        message += 'Mvh tolketjenesten i NAV';
        return message;
    }

    public static String constructMessageToInterpreter(ServiceAppointment sa, String saEvent) {
        String message = 'INFO\n';
        if (saEvent == 'Dispatched') {
            message += sa.Status == 'Dispatched' ? 'Du er tildelt oppdraget ' : 'Du er tatt av oppdraget ';
        }
        if (saEvent == 'Removed') {
            message += 'Du er tatt av oppdraget ';
        }
        message += sa.AppointmentNumber;
        if (saEvent == 'Address') {
            message += ' har endret adresse';
        }
        if (saEvent == 'Time') {
            message += ' har endret tidspunkt';
        }
        if (saEvent == 'CanceledByUser') {
            message += ' ' + formatTimePeriod(sa.EarliestStartTime, sa.DueDate) + ' er avlyst';
        }
        if (saEvent == 'Screen') {
            message += ' ' + formatTimePeriod(sa.EarliestStartTime, sa.DueDate) + ' er endret';
        }
        message += '.\n\nFor mer informasjon, se tolkebestilling.nav.no.\n';
        message += 'Du kan ikke svare på denne meldingen.\n';
        message += 'Mvh tolketjenesten i NAV';
        return message;
    }

    public static String constructOnNewMessage() {
        String message = 'INFO\nDu har fått en melding fra tolketjenesten.\n\n';
        message += 'For mer informasjon, se tolkebestilling.nav.no.\n';
        message += 'Du kan ikke svare på denne meldingen.\n';
        message += 'Mvh tolketjenesten i NAV';
        return message;
    }

    public static String constructOnOrdererMessage(HOT_Request__c request) {
        String message = 'INFO\nDet er bestilt tolk til deg';
        if (request.IsSerieoppdrag__c) {
            message += ' i perioden: ' + request.SeriesPeriod__c;
        } else {
            message += ':\nDato: ' + formatTimePeriod(request.StartTime__c, request.EndTime__c);
        }
        message += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh tolketjenesten i NAV';
        return message;
    }

    public static String constructInterpreterChangedMessage(WorkOrder workOrder, String interpreterNames) {
        String message = 'INFO\nTolk på din bestilling er endret:\n';
        message += 'Tolk er: ';
        message += interpreterNames;
        message += '\nDato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate);
        message += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh tolketjenesten i NAV';
        return message;
    }

    private static String getRecipient(WorkOrder workOrder) {
        if (workOrder.HOT_Request__r.Type__c != 'Me') {
            return workOrder.HOT_Request__r.OrdererPhone__c;
        }
        return workOrder.Account.CRM_Person__r.INT_KrrMobilePhone__c;
    }

    private static String getRecipientOnThread(Thread__c thread) {
        if (thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' || thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK') {
            return thread?.CRM_Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
        } else if (thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER') {
            ServiceResource sr = [
                SELECT AccountId, HOT_MobilePhone__c
                FROM ServiceResource
                WHERE AccountId = :thread.CRM_Account__c
            ];
            return sr?.HOT_MobilePhone__c;
        } else if (thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER') {
            HOT_Request__c request = [
                SELECT Id, OrdererPhone__c
                FROM HOT_Request__c
                WHERE Id = :thread.CRM_Related_Object__c
            ];
            return request?.OrdererPhone__c;
        }
        return '';
    }
    private static String getRecipientPhoneNumberInterpreter(String userId) {
        ServiceResource sr = [
            SELECT RelatedRecordId, HOT_MobilePhone__c
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return sr?.HOT_MobilePhone__c;
    }

    public static String constructStatusChangedMessage(WorkOrder workOrder, String interpreterNames) {
        String message = 'INFO\nStatus på din bestilling er:\n';
        if (workOrder.Status == 'Dispatched') {
            message += 'Du har fått tolk. ';
            message += 'Tolk er: ';
            message += interpreterNames;
        } else if (workOrder.Status == 'Cannot Complete') {
            message += 'Ikke ledig tolk';
        }
        message += '\nDato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate);
        message += '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh tolketjenesten i NAV';
        return message;
    }

    private static String formatTimePeriod(Datetime startDate, Datetime endDate) {
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
}
