public without sharing class HOT_WorkOrderNotification {
    public static void notifyDispatchers_workOrderChanged(List<WorkOrder> workOrders, Map<Id, sObject> triggerOldMap) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_Service_Appointment_Changed'
        ];

        workOrders = checkServiceAppointments(workOrders);

        List<Id> queueIds = new List<Id>();
        List<Id> requestIds = new List<Id>();
        for (WorkOrder workOrder : workOrders) {
            queueIds.add(workOrder.OwnerId);
            requestIds.add(workOrder.HOT_Request__c);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Map<Id, Set<String>> recipientsByGroupId = HOT_NotificationHandler.getUsersInGroup(groupByQueue.values());
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [SELECT Id, Status__c FROM HOT_Request__c WHERE Id IN :requestIds]
        );

        for (WorkOrder workOrder : workOrders) {
            WorkOrder oldWorkOrder = (WorkOrder) triggerOldMap.get(workOrder.Id);

            Set<String> recipients = recipientsByGroupId.get(groupByQueue.get(workOrder.OwnerId));

            // Varsel ved avlyst av bruker
            if (
                workOrder.Status == 'Canceled' &&
                oldWorkOrder.Status != 'Canceled' &&
                requests.get(workOrder.HOT_Request__c).Status__c != 'Avlyst' &&
                recipients != null &&
                !recipients.contains(workOrder.LastModifiedById)
            ) {
                canceledByUser(notificationType, workOrder, recipients);
            }
        }
    }

    public static void canceledByUser(
        CustomNotificationType notificationType,
        WorkOrder workOrder,
        Set<String> recipients
    ) {
        String title = workorder.WorkOrderNumber + ' - ' + workorder.StartDate?.format('d.M.yyyy') + ' - ' + ' Avlyst';
        String body =
            'Arbeidsordren ' +
            workorder.WorkOrderNumber +
            ' som skulle vært gjennomført ' +
            workorder.StartDate?.format('d.M.yyyy') +
            ' er avlyst.';

        Id notificationTypeId = notificationType.Id;
        Id targetId = workorder.Id;

        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationTypeId,
            targetId
        );
        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) workorder);
    }

    public static List<WorkOrder> checkServiceAppointments(List<WorkOrder> unfilteredWorkOrders) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(unfilteredWorkOrders);
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrders.keySet() AND Status != 'Annul'
        ];
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = new Map<Id, List<ServiceAppointment>>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointmentsByWorkOrderId.get(serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId) == null) {
                List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>{ serviceAppointment };
                serviceAppointmentsByWorkOrderId.put(
                    serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                    serviceAppointmentList
                );
            } else {
                serviceAppointmentsByWorkOrderId.get(serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId)
                    .add(serviceAppointment);
            }
        }
        List<WorkOrder> workOrdersToNotify = new List<WorkOrder>();
        for (Id workOrderId : workOrders.keySet()) {
            if (serviceAppointmentsByWorkOrderId.get(workOrderId) != null) {
                Boolean hasOpenServiceAppointment = false;
                for (ServiceAppointment serviceAppointment : serviceAppointmentsByWorkOrderId.get(workOrderId)) {
                    if (serviceAppointment.Status != 'Canceled') {
                        hasOpenServiceAppointment = true;
                        break;
                    }
                }
                if (hasOpenServiceAppointment) {
                    workOrdersToNotify.add(workOrders.get(WorkOrderId));
                }
            }
            else {
                workOrdersToNotify.add(workOrders.get(WorkOrderId));
            }
        }
        return workOrdersToNotify.values();
    }
}
