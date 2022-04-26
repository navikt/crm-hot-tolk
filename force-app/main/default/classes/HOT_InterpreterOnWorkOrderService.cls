public without sharing class HOT_InterpreterOnWorkOrderService {
    @AuraEnabled(cacheable=true)
    public static List<String> getInterpreters(String recordId, String mergeField, String objectName) {
        List<SObject> originRecord = Database.query(
            'SELECT ' +
            mergeField +
            ' FROM ' +
            objectName +
            ' WHERE Id = :recordId'
        );
        Id workOrderId = (Id) originRecord[0].get(mergeField);
        List<String> interpreters = getInterpretersOnWorkOrder(workOrderId);
        return interpreters;
    }

    public static List<String> getInterpretersOnWorkOrder(Id workOrderId) {
        List<String> interpreters = new List<String>();
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = getServiceAppointmentsByWorkOrderId(
            new Set<Id>{ workOrderId }
        );
        if (serviceAppointmentsByWorkOrderId.get(workOrderId) != null) {
            for (ServiceAppointment serviceAppointment : serviceAppointmentsByWorkOrderId.get(workOrderId)) {
                String screenInterpreter = serviceAppointment.HOT_IsScreenInterpreterNew__c ? ' (skjermtolk)' : '';
                interpreters.add(serviceAppointment.HOT_ServiceResource__r.Name + screenInterpreter);
            }
        }
        return interpreters;
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
}
