public without sharing class HOT_ThreadHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Map<Id, Thread__c> threadById = new Map<Id, Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' ||
                thread.CRM_Type__c == 'HOT_BRUKER-BESTILLER' ||
                thread.CRM_Type__c == 'HOT_BRUKER-TOLK' ||
                thread.CRM_Type__c == 'HOT_TOLK-TOLK' ||
                thread.CRM_Type__c == 'HOT_BESTILLER-FORMIDLER' ||
                thread.CRM_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Type__c == 'HOT_TOLK-RESSURSKONTOR' &&
                thread.CRM_Related_Object__c != null
            ) {
                threadById.put(thread.CRM_Related_Object__c, thread);
            }
        }
        if (!threadById.isEmpty()) {
            setDefaultFields(threadById);
        }
    }
    public override void onAfterInsert() {
        Set<Id> workOrderIds = new Set<Id>();
        for (Thread__c t : [
            SELECT Id, CRM_Related_Object__c
            FROM Thread__c
            WHERE Id IN :records AND (CRM_Thread_Type__c = 'HOT_BRUKER-TOLK' OR CRM_Thread_Type__c = 'HOT_TOLK-TOLK')
        ]) {
            workOrderIds.add(t.CRM_Related_Object__c);
        }
        setInterpreterThread(workOrderIds);
    }

    public static String threadSubjectMaker(String subject) {
        if (subject.length() > 80) {
            subject = subject.substring(0, 76) + '...';
        }
        return subject;
    }
    private static void setDefaultFields(Map<Id, Thread__c> threadById) {
        Map<Id, Thread__c> threadByRequestId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByWorkOrderId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByInterestedResourceId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByServiceAppointmentId = new Map<Id, Thread__c>();
        Map<Id, Thread__c> threadByWageClaimId = new Map<Id, Thread__c>();

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
            if (threadId.getSObjectType() == HOT_WageClaim__c.SObjectType) {
                threadByWageClaimId.put(threadId, thread);
            }
        }
        //request
        List<HOT_Request__c> requests = [
            SELECT Id, OwnerId, Subject__c
            FROM HOT_Request__c
            WHERE Id IN :threadByRequestId.keySet()
        ];
        for (HOT_Request__c request : requests) {
            //ingen owner
            if (threadByRequestId.get(request.Id).CRM_Type__c == 'HOT_BRUKER-FORMIDLER') {
                threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
                threadByRequestId.get(request.Id).Name = threadSubjectMaker(
                    'SAMTALE MED BRUKER: ' + request.Subject__c
                );
            } else if (threadByRequestId.get(request.Id).CRM_Type__c == 'HOT_BESTILLER-FORMIDLER') {
                threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
                threadByRequestId.get(request.Id).Name = threadSubjectMaker(
                    'SAMTALE MED BESTILLER: ' + request.Subject__c
                );
            } else if (threadByRequestId.get(request.Id).CRM_Type__c == 'HOT_BRUKER-BESTILLER') {
                threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
                threadByRequestId.get(request.Id).Name = threadSubjectMaker(
                    'SAMTALE MELLOM BRUKER OG BESTILLER: ' + request.Subject__c
                );
            }
        }
        //serviceappointment
        List<ServiceAppointment> serviceAppointment = [
            SELECT Id, Subject, OwnerId
            FROM ServiceAppointment
            WHERE Id IN :threadByServiceAppointmentId.keySet()
        ];
        for (ServiceAppointment sa : serviceAppointment) {
            threadByServiceAppointmentId.get(sa.Id).Name = threadSubjectMaker('SAMTALE MED TOLK: ' + sa.Subject);
            threadByServiceAppointmentId.get(sa.Id).OwnerId = sa.OwnerId;
        }
        //interestedresource
        List<HOT_InterestedResource__c> interestedResource = [
            SELECT Id, ServiceAppointment__r.Subject, ServiceAppointment__r.OwnerId
            FROM HOT_InterestedResource__c
            WHERE Id IN :threadByInterestedResourceId.keySet()
        ];
        for (HOT_InterestedResource__c ir : interestedResource) {
            threadByInterestedResourceId.get(ir.Id).Name = threadSubjectMaker(
                'SAMTALE MED TOLK: ' + ir.ServiceAppointment__r.Subject
            );
            threadByInterestedResourceId.get(ir.Id).OwnerId = ir.ServiceAppointment__r.OwnerId;
        }
        //workorder
        List<WorkOrder> workOrder = [
            SELECT Id, Subject, OwnerId
            FROM WorkOrder
            WHERE Id IN :threadByWorkOrderId.keySet()
        ];
        for (WorkOrder wo : workOrder) {
            if (threadByWorkOrderId.get(wo.Id).CRM_Type__c == 'HOT_BRUKER-TOLK') {
                threadByWorkOrderId.get(wo.Id).Name = threadSubjectMaker(
                    'SAMTALE MELLOM BRUKER OG TOLKER: ' + wo.Subject
                );
                threadByWorkOrderId.get(wo.Id).OwnerId = wo.OwnerId;
            }
            if (threadByWorkOrderId.get(wo.Id).CRM_Type__c == 'HOT_TOLK-TOLK') {
                threadByWorkOrderId.get(wo.Id).Name = threadSubjectMaker('SAMTALE MELLOM MEDTOLKER: ' + wo.Subject);
                threadByWorkOrderId.get(wo.Id).OwnerId = wo.OwnerId;
            }
        }
        //wageclaim
        List<HOT_WageClaim__c> wageClaim = [
            SELECT Id, Name, ServiceAppointment__r.OwnerId
            FROM HOT_WageClaim__c
            WHERE Id IN :threadByWageClaimId.keySet()
        ];
        for (HOT_WageClaim__c wc : wageClaim) {
            threadByWageClaimId.get(wc.Id).Name = threadSubjectMaker('LØNNSKRAV: ' + wc.Name);
            threadByWageClaimId.get(wc.Id).OwnerId = wc.ServiceAppointment__r.OwnerId;
        }
    }

    // NYTT UNDER HER
    @Future
    public static void setInterpreterOnThreadFromServiceAppointment(Set<Id> serviceAppointmentIds) {
        Set<Id> workOrderIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ]) {
            workOrderIds.add(serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId);
        }
        setInterpreterThread(workOrderIds);
    }
    public static void setInterpreterThread(Set<Id> workOrderIds) {
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = getServiceAppointmentsByWorkOrderId(
            workOrderIds
        );

        List<Thread__c> threads = [
            SELECT Id, CRM_Related_Object__c, HOT_Participants__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :workOrderIds
        ];
        for (Thread__c thread : threads) {
            thread.HOT_Participants__c = '';
            if (serviceAppointmentsByWorkOrderId.get(thread.CRM_Related_Object__c) != null) {
                for (
                    ServiceAppointment serviceAppointment : serviceAppointmentsByWorkOrderId.get(
                        thread.CRM_Related_Object__c
                    )
                ) {
                    thread = appendInterpreterName(thread, serviceAppointment);
                }
            }
        }
        HOT_DatabaseOperations.updateRecords(threads);
    }
    private static Map<Id, List<ServiceAppointment>> getServiceAppointmentsByWorkOrderId(Set<Id> workOrderIds) {
        Map<Id, List<ServiceAppointment>> serviceAppointmentsByWorkOrderId = new Map<Id, List<ServiceAppointment>>();
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, Status, HOT_ServiceResource__r.RelatedRecordId, HOT_WorkOrderLineItem__r.WorkOrderId
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
    public static Thread__c appendInterpreterName(Thread__c thread, ServiceAppointment serviceAppointment) {
        String oldInterpreters = thread.HOT_Participants__c;

        if (thread.HOT_Participants__c != '') {
            thread.HOT_Participants__c += ', ' + serviceAppointment.HOT_ServiceResource__r?.RelatedRecordId;
        } else {
            thread.HOT_Participants__c = serviceAppointment.HOT_ServiceResource__r?.RelatedRecordId;
        }
        return thread;
    }
}
