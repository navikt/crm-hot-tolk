public without sharing class HOT_ReminderSMSService {
    public static void reminderSMS(List<WorkOrder> workOrderList) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(workOrderList);
        Map<Id, String> interpreterNames = interpreterNamesByWorkOrderIds(workOrderList);
        List<SMS__c> smsList = new List<SMS__c>();

        for (WorkOrder workOrder : workOrders.values()) {
            smsList.add(
                SMSService.createSMSRecord(
                    'HOT',
                    '24 Hour Scheduled Reminder',
                    workOrder.AccountId,
                    workOrder.Id,
                    workOrder.Account.CRM_Person__r.INT_KrrMobilePhone__c,
                    constructReminderMessage(workOrder, interpreterNames.get(workOrder.Id))
                )
            );
            workOrder.HOT_IsReminderSMSSendt__c = true;
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(workOrders.values());
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

    private static Map<Id, String> interpreterNamesByWorkOrderIds(List<WorkOrder> workOrders) {
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
        for (WorkOrder workOrder : workOrderList) {
            String phoneNumber = getRecipient(workOrder);
            if (
                phoneNumber != null &&
                workOrder.HOT_Interpreters__c != '' && 
                workOrder.HOT_Interpreters__c != null &&
                workOrder.StartDate > Datetime.now() &&
                workOrder.HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c == true &&
                (workOrder.Status == 'Dispatched' ||
                workOrder.Status == 'Cannot Complete')
            ) {
                smsList.add(
                    SMSService.createSMSRecord(
                        'HOT',
                        'Orderer On Status Update',
                        workOrder.HOT_Request__r.Orderer__c,
                        workOrder.Id,
                        phoneNumber,
                        constructStatusChangedMessage(workOrder, interpreterNames.get(workOrder.Id))
                    )
                );
            }
            workOrder.HOT_SendSMSNotificationOnStatusChanged__c = false;
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(workOrderList);
    }

    @Future
    public static void sendSMSOnOrderer(Set<Id> workOrderIds) {
        List<WorkOrder> workOrderList = [
            SELECT
                Id,
                AccountId,
                Status,
                StartDate,
                EndDate,
                HOT_Request__c,
                Account.CRM_Person__r.INT_KrrMobilePhone__c
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (WorkOrder wo : workOrderList) {
            smsList.add(
            SMSService.createSMSRecord(
                        'HOT',
                        'Orderer On Status Update',
                        wo.AccountId,
                        wo.Id,
                        wo.Account.CRM_Person__r.INT_KrrMobilePhone__c,
                        constructOnOrdererMessage(wo)
                    )
            );
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
    public static void sendSMSOnInterpreterChange(Set<Id> workOrderIds, String interpreterName) {
        List<WorkOrder> workOrderList = [
            SELECT
                Id,
                AccountId,
                Status,
                StartDate,
                EndDate,
                HOT_Request__c,
                HOT_Request__r.Type__c,
                HOT_Request__r.OrdererPhone__c,
                Account.CRM_Person__r.INT_KrrMobilePhone__c
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];
        List<SMS__c> smsList = new List<SMS__c>();

        for (WorkOrder wo : workOrderList) {
            smsList.add(
                SMSService.createSMSRecord(
                            'HOT',
                            'Orderer On Status Update',
                            wo.AccountId,
                            wo.Id,
                            getRecipient(wo),
                            constructInterpreterChangedMessage(wo, interpreterName)
                        )
                );
        }
        try {
            HOT_DatabaseOperations.insertRecords(smsList);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static String constructOnOrdererMessage(WorkOrder workOrder) {
        String message = 'INFO\nAndre har lagt inn en bestilling for deg:\n';
        message += '\nDato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate);
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
