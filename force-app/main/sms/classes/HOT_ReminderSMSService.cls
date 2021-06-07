public without sharing class HOT_ReminderSMSService {
    public static void reminderSMS(List<WorkOrder> workOrderList) {
        Date dayAfterTomorrow = Date.today().addDays(2);
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
            String message = constructReminderMessage(workOrder, serviceAppointmentsByWorkOrderId.get(workOrder.Id));
            SMS__c sms = new SMS__c();
            sms.Domain__c = 'HOT';
            sms.Type__c = '24 Hour Scheduled Reminder';
            sms.Account__c = workOrder.AccountId;
            sms.WorkOrder__c = workOrder.Id;
            sms.Recipient__c = workOrder.Account.CRM_Person__r.INT_KrrMobilePhone__c;
            sms.Message__c = message;
            smsList.add(sms);

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
        message += '\n\nGi beskjed dersom du har symptomer på Korona. For mer informasjon tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
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
