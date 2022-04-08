public without sharing class HOT_InterpreterOnWorkOrderService {
    public static void setInterpreterOnWorkOrder(Set<Id> workOrderIds) {
        System.debug('vegard: setInterpreterOnWorkOrder');
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = getServiceAppointmentsByWorkOrderId(
            workOrderIds
        );
        List<WorkOrder> workOrders = new List<WorkOrder>();
        System.debug('vegard: pre for');
        for (Id workOrderId : workOrderIds) {
            WorkOrder workOrder = new WorkOrder(Id = workOrderId, HOT_Interpreters__c = '');
            System.debug('vegard: ' + workOrder.HOT_Interpreters__c);
            System.debug('vegard: ' + serviceAppointmentsByWorkOrderId.get(workOrderId));
            if (serviceAppointmentsByWorkOrderId.get(workOrderId) != null) {
                for (ServiceAppointment serviceAppointment : serviceAppointmentsByWorkOrderId.get(workOrderId)) {
                    appendInterpreterName(workOrder, serviceAppointment);
                }
                workOrder.HOT_Interpreters__c = workOrder.HOT_Interpreters__c.removeEnd(', ');
            }
            workOrders.add(workOrder);
        }
        update workOrders;
        System.debug([SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE Id IN :workOrderIds]);
    }

    private static Map<Id, List<ServiceAppointment>> getServiceAppointmentsByWorkOrderId(Set<Id> workOrderIds) {
        System.debug('vegard: getServiceAppointmentsByWorkOrderId');
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = new Map<Id, List<ServiceAppointment>>();
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                Status,
                ParentRecordId,
                HOT_ServiceResource__r.Name,
                HOT_IsScreenInterpreterNew__c,
                HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds
                AND Status != 'Scheduled'
                AND HOT_ServiceResource__r.Name != NULL
        ];
        System.debug('vegard: ' + workOrderIds);
        System.debug('vegard: ' + serviceAppointments);
        System.debug('vegard: ' + serviceAppointments.size());
        System.debug(
            'vegard: ' +
            [
                SELECT
                    Id,
                    Status,
                    ParentRecordId,
                    HOT_ServiceResource__r.Name,
                    HOT_IsScreenInterpreterNew__c,
                    HOT_WorkOrderLineItem__r.WorkOrderId
                FROM ServiceAppointment
                WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds
            ]
        );
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (
                !serviceAppointmentsByWorkOrderId.containsKey(serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId)
            ) {
                serviceAppointmentsByWorkOrderId.put(
                    serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                    new List<ServiceAppointment>{ serviceAppointment }
                );
            } else {
                serviceAppointmentsByWorkOrderId.get(serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId)
                    .add(serviceAppointment);
            }
        }
        return serviceAppointmentsByWorkOrderId;
    }

    private static WorkOrder appendInterpreterName(WorkOrder workOrder, ServiceAppointment serviceAppointment) {
        String screenInterpreter = serviceAppointment.HOT_IsScreenInterpreterNew__c ? ' (skjermtolk)' : '';
        workOrder.HOT_Interpreters__c += serviceAppointment.HOT_ServiceResource__r.Name + screenInterpreter + ', ';
        return workOrder;
    }

    public static void setInterpreterOnWorkOrderFromServiceAppointment(Set<Id> serviceAppointmentIds) {
        System.debug('vegard setInterpreterOnWorkOrderFromServiceAppointment');
        Set<Id> workOrderIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ]) {
            workOrderIds.add(serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId);
        }
        setInterpreterOnWorkOrder(workOrderIds);
    }
}
