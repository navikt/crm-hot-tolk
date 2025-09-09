public without sharing class HOT_ThreadHandler extends MyTriggers implements Callable{
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    public override void onBeforeInsert() {
        Map<Id, Thread__c> threadById = new Map<Id, Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                (thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' ||
                thread.CRM_Type__c == 'HOT_BRUKER-BESTILLER' ||
                thread.CRM_Type__c == 'HOT_BRUKER-TOLK' ||
                thread.CRM_Type__c == 'HOT_TOLK-TOLK' ||
                thread.CRM_Type__c == 'HOT_BESTILLER-FORMIDLER' ||
                thread.CRM_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Type__c == 'HOT_TOLK-RESSURSKONTOR') &&
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
        List<Thread__c> threadsOfInterest = new List<Thread__c>();
        List<Thread__c> threads = (List<Thread__c>) records;
        Set<String> threadTypesOfInterest = new Set<String>{'HOT_TOLK-TOLK','HOT_TOLK-FORMIDLER'};

        for(Thread__c t : threads){
            if(threadTypesOfInterest.contains(t.CRM_Thread_Type__c)){
                threadsOfInterest.add(t);
            }
        }
        setInterpreter(threadsOfInterest);
    }
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'setInterpreter' {
                HOT_ThreadHandler.setInterpreter((List<Thread__c>) args.get('threads'));
                return true;
            }
            when else {
                throw new HOT_ThreadHandlerCallException('Method not implemented');
            }
        }
    }

    public class HOT_ThreadHandlerCallException extends Exception {
    }
    public static void setInterpreter(List<Thread__c> threads){
        Set<Id> workOrderIds = new Set<Id>();
        for (Thread__c t : threads){
 
            if(((Id)t.CRM_Related_Object__c).getSObjectType() == WorkOrder.SObjectType){
                workOrderIds.add(t.CRM_Related_Object__c);
            }
        }

        if (workOrderIds.size() > 0) {
            setInterpreterThread(threads, getServiceAppointmentsByWorkOrderId(workOrderIds));
        }
        if(threads.size() > 0){
            setInterpreterOnThreadOneToOne(threads);
        }
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
        if(threadByServiceAppointmentId.size() > 0){
            List<ServiceAppointment> serviceAppointment = [
                SELECT Id, Subject, OwnerId
                FROM ServiceAppointment
                WHERE Id IN :threadByServiceAppointmentId.keySet()
            ];
            for (ServiceAppointment sa : serviceAppointment) {
                threadByServiceAppointmentId.get(sa.Id).Name = threadSubjectMaker('SAMTALE MED TOLK: ' + sa.Subject);
                threadByServiceAppointmentId.get(sa.Id).OwnerId = sa.OwnerId;
            }
        }
        //interestedresource
        if(threadByInterestedResourceId.size() > 0){
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
        }
        //workorder
        if(threadByWorkOrderId.size() > 0){
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
        }
        //wageclaim
        if(threadByWageClaimId.size() > 0){
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
            SELECT Id, CRM_Related_Object__c, HOT_ParticipantIds__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :workOrderIds
        ];
        setInterpreterThread(threads, serviceAppointmentsByWorkOrderId);
    }

    private static void setInterpreterThread(List<Thread__c> threads, Map<Id,List<ServiceAppointment>> saByWoIdMap){
        List<Thread__c> threadsToUpdate = new List<Thread__c>();
        for(Thread__c thread : threads){
            if(!saByWoIdMap.containsKey(thread.CRM_Related_Object__c)){
                continue;
            }
            Set<String> newParticipantIds = new Set<String>();
            Set<String> oldParticipantIds = new Set<String>(thread.HOT_ParticipantIds__c?.split(',')??new List<String>());
            for(ServiceAppointment sa : saByWoIdMap.get(thread.CRM_Related_Object__c)){
                if(sa.HOT_ServiceResource__r == null){
                    continue;
                }
                newParticipantIds.add(sa.HOT_ServiceResource__r.RelatedRecordId);
            }
            if(!newParticipantIds.equals(oldParticipantIds)){
                threadsToUpdate.add(
                    new Thread__c(
                        Id = thread.Id, 
                        HOT_ParticipantIds__c = String.join(
                            new List<String>(newParticipantIds),
                            ','
                        )
                    )
                );
            }
            
        }
        if(threadsToUpdate.isEmpty()){
            return;
        }
        try {
            HOT_DatabaseOperations.updateRecords(threadsToUpdate);
        } catch (Exception e) {
            handleException(e);
        }
    }

    private static void setInterpreterOnThreadOneToOne(List<Thread__c> threads){
        Set<Id> relatedSA = new Set<Id>();
        Set<Id> relatedIR = new Set<Id>();
        for(Thread__c t : threads){
            if(t.CRM_Related_Object__c == null){
                continue;
            }
            if(
                ((Id) t.CRM_Related_Object__c).getSObjectType() == ServiceAppointment.SObjectType
            ){
                relatedSA.add(t.CRM_Related_Object__c);
            }else if(
                ((Id) t.CRM_Related_Object__c).getSObjectType() == HOT_InterestedResource__c.SObjectType
            ){
                relatedIR.add(t.CRM_Related_Object__c);
            }
        }
        Map<Id,ServiceAppointment> serviceAppointmentMap = new Map<Id,ServiceAppointment>([
            SELECT Id, HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE Id IN :relatedSA
        ]);
        Map<Id,HOT_InterestedResource__c> interestedResourceMap = new Map<Id, HOT_InterestedResource__c>([
            SELECT Id, ServiceResource__r.RelatedRecordId
            FROM HOT_InterestedResource__c
            WHERE Id IN :relatedIR
        ]);
        List<Thread__c> threadsToUpdate = new List<Thread__c>();
        for(Thread__c t : threads){
            if(
                serviceAppointmentMap.containsKey(t.CRM_Related_Object__c)
            ){
                ServiceAppointment sa = serviceAppointmentMap.get(t.CRM_Related_Object__c);
                if(
                    sa.HOT_ServiceResource__r.RelatedRecordId != null
                    && t.HOT_ParticipantIds__c != sa.HOT_ServiceResource__r.RelatedRecordId
                ){
                    //t.HOT_ParticipantIds__c = sa.HOT_ServiceResource__r.RelatedRecordId;
                    threadsToUpdate.add(
                        new Thread__c(
                            Id = t.Id,
                            HOT_ParticipantIds__c = sa.HOT_ServiceResource__r.RelatedRecordId
                        )
                    );
                }
            }else if(
                interestedResourceMap.containsKey(t.CRM_Related_Object__c)
            ){
                HOT_InterestedResource__c ir = interestedResourceMap.get(t.CRM_Related_Object__c);
                if(
                    t.HOT_ParticipantIds__c != ir.ServiceResource__r.RelatedRecordId
                ){
                    //t.HOT_ParticipantIds__c = ir.ServiceResource__r.RelatedRecordId;
                    threadsToUpdate.add(
                        new Thread__c(
                            Id = t.Id,
                            HOT_ParticipantIds__c = ir.ServiceResource__r.RelatedRecordId
                        )
                    );
                }
            }
        }
        if(threadsToUpdate.isEmpty()){
            return;
        }
        try {
            HOT_DatabaseOperations.updateRecords(threadsToUpdate);
        } catch (Exception e) {
            handleException(e);
        }
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
}
