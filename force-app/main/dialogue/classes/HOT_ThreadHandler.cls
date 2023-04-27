public without sharing class HOT_ThreadHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Map<Id, Thread__c> threadById = new Map<Id, Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' || thread.CRM_Type__c == 'HOT_BRUKER-TOLK' || thread.CRM_Type__c == 'HOT_BESTILLER-FORMIDLER' || thread.CRM_Type__c == 'HOT_TOLK-FORMIDLER' && thread.CRM_Related_Object__c != null) {
                    threadById.put(thread.CRM_Related_Object__c, thread);
            }
        }
        if (!threadById.isEmpty()) {
            setDefaultFields(threadById);
        }
    }
    public override void onAfterInsert() {
    }

    private static void setDefaultFields(Map<Id, Thread__c> threadById) {
        Map<Id, Thread__c> threadByRequestId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByWorkOrderId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByInterestedResourceId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByServiceAppointmentId = new Map<Id, Thread__c>();

        for (Id threadId : threadById.keySet()) {
           Thread__c thread = threadById.get(threadId);
                if (threadId.getSObjectType() == HOT_Request__c.SObjectType) {
                    threadByRequestId.put(threadId, thread);
                }
                if (threadId.getSObjectType() == WorkOrder.SObjectType) {
                    threadByWorkOrderId.put(threadId, thread);
                }
                if (threadId.getSObjectType() == HOT_InterestedResource__c.SObjectType) {
                    threadByInterestedResourceId.put(threadId, thread);                
                }
                if (threadId.getSObjectType() == ServiceAppointment.SObjectType) {
                    threadByServiceAppointmentId.put(threadId, thread);
                }
        }
        //request
        List<HOT_Request__c> requests = [
            SELECT Id, OwnerId, Subject__c
            FROM HOT_Request__c
            WHERE Id IN :threadByRequestId.keySet()
        ];
        for (HOT_Request__c request : requests) {
            threadByRequestId.get(request.Id).Name = request.Subject__c.left(80);
        }
        //serviceappointment
         List<ServiceAppointment> serviceAppointment = [
            SELECT Id, Subject
            FROM ServiceAppointment
            WHERE Id IN :threadByServiceAppointmentId.keySet()
        ];
        for (ServiceAppointment sa : serviceAppointment) {
            threadByServiceAppointmentId.get(sa.Id).Name = sa.Subject.left(80);
        }
        //interestedresource
         List<HOT_InterestedResource__c> interestedResource = [
            SELECT Id, ServiceAppointment__r.Subject
            FROM HOT_InterestedResource__c
            WHERE Id IN :threadByInterestedResourceId.keySet()
        ];
        for (HOT_InterestedResource__c ir : interestedResource) {
            threadByInterestedResourceId.get(ir.Id).Name = ir.ServiceAppointment__r.Subject.left(80);
        }
        //workorder
         List<WorkOrder> workOrder = [
            SELECT Id, Subject
            FROM WorkOrder
            WHERE Id IN :threadByWorkOrderId.keySet()
        ];
        for (WorkOrder wo : workOrder) {
            threadByWorkOrderId.get(wo.Id).Name = wo.Subject.left(80);
        }
    }
}
