public without sharing class HOT_ReminderSMSService {
    public static void reminderSMS(List<WorkOrder> workOrderList) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(workOrderList);
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
            WHERE WorkOrderId IN :workOrders.keySet()
        ];
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = new Map<Id, List<ServiceAppointment>>();
        for (WorkOrderLineItem woli : workOrderLineItems) {
            if (serviceAppointmentsByWorkOrderId.get(woli.WorkOrderId) == null) {
                serviceAppointmentsByWorkOrderId.put(
                    woli.WorkOrderId,
                    new List<ServiceAppointment>(woli.HOT_ServiceAppointments__r)
                );
            } else {
                serviceAppointmentsByWorkOrderId.get(woli.WorkOrderId).addAll(woli.HOT_ServiceAppointments__r);
            }
        }

        List<SMS__c> smsList = new List<SMS__c>();
        for (WorkOrder workOrder : workOrders.values()) {
            smsList.add(
                SMSService.createSMSRecord(
                    'HOT',
                    '24 Hour Scheduled Reminder',
                    workOrder.AccountId,
                    workOrder.Id,
                    workOrder.Account.CRM_Person__r.INT_KrrMobilePhone__c,
                    constructReminderMessage(workOrder, serviceAppointmentsByWorkOrderId.get(workOrder.Id))
                )
            );
            workOrder.HOT_IsReminderSMSSendt__c = true;
        }

        try {
            insert smsList;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, null, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }

        try {
            update workOrders.values();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, null, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    private static String constructReminderMessage(WorkOrder workOrder, List<ServiceAppointment> serviceAppointments) {
        String message = 'PÅMINNELSE\nVi minner om tolkebestilling:\n';
        message += 'Dato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate) + '\n';
        message += 'Tolk er: ';
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            message += serviceAppointment.HOT_ServiceResource__r.Name + ', ';
        }
        message = message.removeEnd(', ');
        message += '\n\nGi beskjed dersom du har symptomer på Korona. For mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh NAV Tolketjeneste';
        return message;
    }

    private static List<String> tolkNames(Id workOrderId) {
        List<String> tolkNames = new List<String>();
        List<ServiceAppointment> ServiceAppointments = serviceAppointmentsByWorkOrderId.get(workOrder.Id);
    }

    public static void sendSMSToOtherOrdererOnStatusUpdate(List<WorkOrder> workOrderList) {
        List<SMS__c> smsList = new List<SMS__c>();
        for (WorkOrder workOrder : workOrderList) {
            if (
                workOrder.HOT_Request__r.OrdererPhone__c != null &&
                workOrder.StartDate > Datetime.now() &&
                workOrder.HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c == true &&
                (workOrder.Status == 'Dispatched' ||
                workOrder.Status == 'Cannot Complete')
            ) {
                smsList.add(
                    SMSService.createSMSRecord(
                        'HOT',
                        'Orderer On Status Update',
                        workOrder.AccountId,
                        workOrder.Id,
                        workOrder.HOT_Request__r.OrdererPhone__c,
                        constructStatusChangedMessage(workOrder)
                    )
                );
            }
            workOrder.HOT_SendSMSNotificationOnStatusChanged__c = false;
        }

        try {
            insert smsList;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, null, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }

        try {
            update workOrderList;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, null, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    private static String constructStatusChangedMessage(
        WorkOrder workOrder,
        List<ServiceAppointment> serviceAppointments
    ) {
        String message = 'INFO\nStatus på din bestilling er: ';
        if (workOrder.Status == 'Dispatched') {
            message += 'Du har fått tolk';
            message += 'Tolk er: ';
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                message += serviceAppointment.HOT_ServiceResource__r.Name + ', ';
            }
        } else if (workOrder.Status == 'Cannot Complete') {
            message += 'Ikke ledig tolk';
        }
        message += '\nDato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate);
        message += '\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh NAV Tolketjeneste';
        return message;
    }

    private static String formatTimePeriod(Datetime startDate, Datetime endDate) {
        String timePeriod =
            startDate.date().format() +
            ', kl. ' +
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
