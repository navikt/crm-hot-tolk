public without sharing class HOT_ReminderSMSService {
    public static void reminderSMS(List<WorkOrder> workOrderList) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(workOrderList);
        Map<Id, String> tolkNames = tolkNamesByWorkOrderId(workOrderList);
        List<SMS__c> smsList = new List<SMS__c>();

        for (WorkOrder workOrder : workOrders.values()) {
            smsList.add(
                SMSService.createSMSRecord(
                    'HOT',
                    '24 Hour Scheduled Reminder',
                    workOrder.AccountId,
                    workOrder.Id,
                    workOrder.Account.CRM_Person__r.INT_KrrMobilePhone__c,
                    constructReminderMessage(workOrder, tolkNames.get(workOrder.Id))
                )
            );
            workOrder.HOT_IsReminderSMSSendt__c = true;
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(workOrders.values());
    }

    private static Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId(List<WorkOrder> workOrders) {
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
        return serviceAppointmentsByWorkOrderId;
    }

    private static Map<Id, String> tolkNamesByWorkOrderId(List<WorkOrder> workOrders) {
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = serviceAppointmentsByWorkOrderId(
            workOrders
        );
        Map<Id, String> tolkNamesByWorkOrderIds = new Map<Id, String>();

        for (WorkOrder workOrder : workOrders) {
            Id workOrderId = workOrder.Id;
            String tolkNames = 'Tolk er: ';
            List<ServiceAppointment> serviceAppointemts = serviceAppointmentsByWorkOrderId.get(workOrderId);
            for (Integer i = 0; i < serviceAppointemts.size(); i++) {
                tolkNames += serviceAppointemts[i].HOT_ServiceResource__r.Name;
                if (i == serviceAppointemts.size() - 1) {
                    tolkNames += '. ';
                } else {
                    tolkNames += ', ';
                }
            }
            tolkNamesByWorkOrderIds.put(workOrderId, tolkNames);
        }
        return tolkNamesByWorkOrderIds;
    }

    private static String constructReminderMessage(WorkOrder workOrder, String tolkNames) {
        String message = 'PÅMINNELSE\nVi minner om tolkebestilling:\n';
        message += 'Dato: ' + formatTimePeriod(workOrder.StartDate, workOrder.EndDate) + '\n';
        message += tolkNames;
        message = message.removeEnd(', ');
        message += '\n\nGi beskjed dersom du har symptomer på Korona. For mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.';
        message += '\nMvh NAV Tolketjeneste';
        return message;
    }

    public static void sendSMSToOrdererOnStatusUpdate(List<WorkOrder> workOrderList) {
        Map<Id, String> tolkNames = tolkNamesByWorkOrderId(workOrderList);
        List<SMS__c> smsList = new List<SMS__c>();
        for (WorkOrder workOrder : workOrderList) {
            String phoneNumber = getRecipient(workOrder);
            if (
                phoneNumber != null &&
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
                        workOrder.HOT_Request__r.OrdererPhone__c,
                        constructStatusChangedMessage(workOrder, tolkNames.get(workOrder.Id))
                    )
                );
            }
            workOrder.HOT_SendSMSNotificationOnStatusChanged__c = false;
        }
        HOT_DatabaseOperations.insertRecords(smsList);
        HOT_DatabaseOperations.updateRecords(workOrderList);
    }

    private static String getRecipient(WorkOrder workOrder) {
        if (workOrder.HOT_Request__r.Type__c != 'Me') {
            return workOrder?.HOT_Request__r?.OrdererPhone__c;
        }
        return workOrder?.Account?.CRM_Person__r?.INT_KrrMobilePhone__c;
    }

    private static String constructStatusChangedMessage(WorkOrder workOrder, String tolkNames) {
        String message = 'INFO\nStatus på din bestilling er: ';
        if (workOrder.Status == 'Dispatched') {
            message += 'Du har fått tolk. ';
            message += tolkNames;
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
