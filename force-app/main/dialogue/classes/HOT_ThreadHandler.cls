public without sharing class HOT_ThreadHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Map<Id, Thread__c> threadById = new Map<Id, Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' ||thread.CRM_Type__c == 'HOT_BRUKER-BESTILLER' || thread.CRM_Type__c == 'HOT_BRUKER-TOLK' || thread.CRM_Type__c == 'HOT_TOLK-TOLK' || thread.CRM_Type__c == 'HOT_BESTILLER-FORMIDLER' || thread.CRM_Type__c == 'HOT_TOLK-FORMIDLER' || thread.CRM_Type__c == 'HOT_TOLK-RESSURSKONTOR' && thread.CRM_Related_Object__c != null) {
                    threadById.put(thread.CRM_Related_Object__c, thread);
            }
        }
        if (!threadById.isEmpty()) {
            setDefaultFields(threadById);
        }
    }
    public override void onAfterInsert() {
    }

    public static String threadSubjectMaker(String subject){
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
                    threadByRequestId.get(request.Id).Name = threadSubjectMaker('SAMTALE MED BRUKER: '+request.Subject__c);
              }
              else if(threadByRequestId.get(request.Id).CRM_Type__c == 'HOT_BESTILLER-FORMIDLER'){
                    threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
                    threadByRequestId.get(request.Id).Name = threadSubjectMaker('SAMTALE MED BESTILLER: '+request.Subject__c);
              }
              else if(threadByRequestId.get(request.Id).CRM_Type__c == 'HOT_BRUKER-BESTILLER'){
                     threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
                     threadByRequestId.get(request.Id).Name = threadSubjectMaker('SAMTALE MELLOM BRUKER OG BESTILLER: '+request.Subject__c);              
            }
        }
        //serviceappointment
         List<ServiceAppointment> serviceAppointment = [
            SELECT Id, Subject, OwnerId
            FROM ServiceAppointment
            WHERE Id IN :threadByServiceAppointmentId.keySet()
        ];
        for (ServiceAppointment sa : serviceAppointment) {
            threadByServiceAppointmentId.get(sa.Id).Name = threadSubjectMaker('SAMTALE MED TOLK: '+sa.Subject);
            threadByServiceAppointmentId.get(sa.Id).OwnerId = sa.OwnerId;
        }
        //interestedresource
         List<HOT_InterestedResource__c> interestedResource = [
            SELECT Id, ServiceAppointment__r.Subject, ServiceAppointment__r.OwnerId
            FROM HOT_InterestedResource__c
            WHERE Id IN :threadByInterestedResourceId.keySet()
        ];
        for (HOT_InterestedResource__c ir : interestedResource) {
            threadByInterestedResourceId.get(ir.Id).Name = threadSubjectMaker('SAMTALE MED TOLK: '+ir.ServiceAppointment__r.Subject);
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
                threadByWorkOrderId.get(wo.Id).Name = threadSubjectMaker('SAMTALE MELLOM BRUKER OG TOLKER: '+wo.Subject);
                threadByWorkOrderId.get(wo.Id).OwnerId = wo.OwnerId;
            }
            if (threadByWorkOrderId.get(wo.Id).CRM_Type__c == 'HOT_TOLK-TOLK') {
                threadByWorkOrderId.get(wo.Id).Name = threadSubjectMaker('SAMTALE MELLOM MEDTOLKER: '+wo.Subject);
                threadByWorkOrderId.get(wo.Id).OwnerId = wo.OwnerId;
            }
        }
        //wageclaim
        List<HOT_WageClaim__c> wageClaim =[SELECT Id, Name, ServiceAppointment__r.OwnerId FROM HOT_WageClaim__c WHERE Id IN: threadByWageClaimId.keySet()];
        for (HOT_WageClaim__c wc : wageClaim) {
            threadByWageClaimId.get(wc.Id).Name = threadSubjectMaker('LØNNSKRAV: '+wc.Name);
            threadByWageClaimId.get(wc.Id).OwnerId=wc.ServiceAppointment__r.OwnerId;
        }

    }
}
