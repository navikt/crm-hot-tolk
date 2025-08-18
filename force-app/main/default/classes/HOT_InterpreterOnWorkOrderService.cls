public without sharing class HOT_InterpreterOnWorkOrderService {
    public static void setInterpreterOnWorkOrder(Set<Id> workOrderIds) {
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = getServiceAppointmentsByWorkOrderId(
            workOrderIds
        );
        List<WorkOrder> workOrders = [SELECT Id, HOT_Interpreters__c, Status FROM WorkOrder WHERE Id IN :workOrderIds];
        for (WorkOrder workOrder : workOrders) {
            workOrder.HOT_Interpreters__c = '';
            if (serviceAppointmentsByWorkOrderId.get(workOrder.Id) != null) {
                for (ServiceAppointment serviceAppointment : serviceAppointmentsByWorkOrderId.get(workOrder.Id)) {
                    if (
                        workOrder.Status == 'Completed' ||
                        workOrder.Status == 'Partially Complete' ||
                        workOrder.Status == 'Dispatched'
                    ) {
                        workOrder = appendInterpreterName(workOrder, serviceAppointment);
                    }
                }
            }
        }
        HOT_DatabaseOperations.updateRecords(workOrders);
    }

    private static Map<Id, List<ServiceAppointment>> getServiceAppointmentsByWorkOrderId(Set<Id> workOrderIds) {
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

    public static WorkOrder appendInterpreterName(WorkOrder workOrder, ServiceAppointment serviceAppointment) {
        String oldInterpreters = workOrder.HOT_Interpreters__c;
        String screenInterpreter = serviceAppointment.HOT_IsScreenInterpreterNew__c ? ' (skjermtolk)' : '';

        if (workOrder.HOT_Interpreters__c != '') {
            workOrder.HOT_Interpreters__c += ', ' + serviceAppointment.HOT_ServiceResource__r?.Name + screenInterpreter;
        } else {
            workOrder.HOT_Interpreters__c = serviceAppointment.HOT_ServiceResource__r?.Name + screenInterpreter;
        }

        if (workOrder.HOT_Interpreters__c.length() > 255) {
            workOrder.HOT_Interpreters__c = workOrder.HOT_Interpreters__c.substring(0, 252) + '...';
        }

        return workOrder;
    }

    public class workOrderInvocableWrapper {
        @InvocableVariable(label='Service Appointments')
        public List<ServiceAppointment> serviceAppointments;
    }

    @InvocableMethod(label='Set Interpreter field on Work Order')
    public static void setInterpreterOnWorkOrderFromServiceAppointmentInvokable(
        List<workOrderInvocableWrapper> wrapperList
    ) {
        Set<Id> saIds = new Set<Id>();

        for (workOrderInvocableWrapper wrapper : wrapperList) {
            if (wrapper.serviceAppointments != null) {
                for (ServiceAppointment sa : wrapper.serviceAppointments) {
                    saIds.add(sa.Id);
                }
            }
        }

        setInterpreterOnWorkOrderFromServiceAppointment(saIds);
    }

    @Future
    public static void setInterpreterOnWorkOrderFromServiceAppointment(Set<Id> serviceAppointmentIds) {
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
