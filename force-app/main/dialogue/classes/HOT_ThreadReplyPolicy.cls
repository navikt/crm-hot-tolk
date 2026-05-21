public without sharing class HOT_ThreadReplyPolicy {
    private static final String RESOURCE_OFFICE_THREAD_TYPE = 'HOT_TOLK-RESSURSKONTOR';
    private static final Integer REPLY_WINDOW_HOURS = 48;

    public class ReplyPolicy {
        @AuraEnabled
        public Id threadId;
        @AuraEnabled
        public Boolean canReply;
        @AuraEnabled
        public Datetime replyClosedAt;
        @AuraEnabled
        public Datetime appointmentEndTime;

        public ReplyPolicy(Id threadId, Boolean canReply, Datetime replyClosedAt, Datetime appointmentEndTime) {
            this.threadId = threadId;
            this.canReply = canReply;
            this.replyClosedAt = replyClosedAt;
            this.appointmentEndTime = appointmentEndTime;
        }
    }

    public static void addErrorsForClosedThreads(List<Message__c> messages) {
        Set<Id> threadIds = new Set<Id>();
        for (Message__c message : messages) {
            if (message.CRM_Thread__c != null) {
                threadIds.add(message.CRM_Thread__c);
            }
        }
        if (threadIds.isEmpty()) {
            return;
        }

        Map<Id, ReplyPolicy> policiesByThreadId = getReplyPolicies(threadIds);
        for (Message__c message : messages) {
            ReplyPolicy policy = policiesByThreadId.get(message.CRM_Thread__c);
            if (policy != null && !policy.canReply) {
                message.addError('Denne samtalen er stengt for videre dialog.');
            }
        }
    }

    public static Map<Id, ReplyPolicy> getReplyPolicies(Set<Id> threadIds) {
        Map<Id, ReplyPolicy> result = new Map<Id, ReplyPolicy>();
        if (threadIds == null || threadIds.isEmpty()) {
            return result;
        }

        Set<Id> validThreadIds = new Set<Id>();
        for (Id threadId : threadIds) {
            if (threadId != null) {
                validThreadIds.add(threadId);
            }
        }

        if (validThreadIds.isEmpty()) {
            return result;
        }

        List<Thread__c> threads = [
            SELECT
                Id,
                CRM_Thread_Type__c,
                CRM_Related_Object__c,
                HOT_Request__c,
                HOT_WorkOrder__c,
                HOT_ServiceAppointment__c,
                HOT_InterestedResource__c
            FROM Thread__c
            WHERE Id IN :validThreadIds
        ];

        Map<Id, Id> requestIdByThreadId = new Map<Id, Id>();
        Map<Id, Id> workOrderIdByThreadId = new Map<Id, Id>();
        Map<Id, Id> serviceAppointmentIdByThreadId = new Map<Id, Id>();
        Map<Id, Id> interestedResourceIdByThreadId = new Map<Id, Id>();
        Set<Id> requestIds = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> serviceAppointmentIds = new Set<Id>();
        Set<Id> interestedResourceIds = new Set<Id>();

        for (Thread__c thread : threads) {
            if (thread.CRM_Thread_Type__c == RESOURCE_OFFICE_THREAD_TYPE) {
                result.put(thread.Id, new ReplyPolicy(thread.Id, true, null, null));
                continue;
            }

            Id relatedId = thread.CRM_Related_Object__c;
            if (thread.HOT_Request__c != null) {
                requestIdByThreadId.put(thread.Id, thread.HOT_Request__c);
                requestIds.add(thread.HOT_Request__c);
            } else if (relatedId != null && relatedId.getSObjectType() == HOT_Request__c.SObjectType) {
                requestIdByThreadId.put(thread.Id, relatedId);
                requestIds.add(relatedId);
            }

            if (thread.HOT_WorkOrder__c != null) {
                workOrderIdByThreadId.put(thread.Id, thread.HOT_WorkOrder__c);
                workOrderIds.add(thread.HOT_WorkOrder__c);
            } else if (relatedId != null && relatedId.getSObjectType() == WorkOrder.SObjectType) {
                workOrderIdByThreadId.put(thread.Id, relatedId);
                workOrderIds.add(relatedId);
            }

            if (thread.HOT_ServiceAppointment__c != null) {
                serviceAppointmentIdByThreadId.put(thread.Id, thread.HOT_ServiceAppointment__c);
                serviceAppointmentIds.add(thread.HOT_ServiceAppointment__c);
            } else if (relatedId != null && relatedId.getSObjectType() == ServiceAppointment.SObjectType) {
                serviceAppointmentIdByThreadId.put(thread.Id, relatedId);
                serviceAppointmentIds.add(relatedId);
            }

            if (thread.HOT_InterestedResource__c != null) {
                interestedResourceIdByThreadId.put(thread.Id, thread.HOT_InterestedResource__c);
                interestedResourceIds.add(thread.HOT_InterestedResource__c);
            } else if (relatedId != null && relatedId.getSObjectType() == HOT_InterestedResource__c.SObjectType) {
                interestedResourceIdByThreadId.put(thread.Id, relatedId);
                interestedResourceIds.add(relatedId);
            }
        }

        Map<Id, Datetime> endTimeByRequestId = getLatestServiceAppointmentEndByRequestId(requestIds);
        Map<Id, Datetime> fallbackEndTimeByRequestId = getFallbackEndByRequestId(requestIds);
        Map<Id, Datetime> endTimeByWorkOrderId = getLatestServiceAppointmentEndByWorkOrderId(workOrderIds);
        Map<Id, Datetime> fallbackEndTimeByWorkOrderId = getFallbackEndByWorkOrderId(workOrderIds);
        Map<Id, Datetime> endTimeByServiceAppointmentId = getEndByServiceAppointmentId(serviceAppointmentIds);
        Map<Id, Id> serviceAppointmentIdByInterestedResourceId = getServiceAppointmentIdByInterestedResourceId(
            interestedResourceIds
        );

        for (Id serviceAppointmentId : serviceAppointmentIdByInterestedResourceId.values()) {
            serviceAppointmentIds.add(serviceAppointmentId);
        }
        endTimeByServiceAppointmentId.putAll(getEndByServiceAppointmentId(serviceAppointmentIds));

        for (Thread__c thread : threads) {
            if (result.containsKey(thread.Id)) {
                continue;
            }

            Datetime endTime;
            if (serviceAppointmentIdByThreadId.containsKey(thread.Id)) {
                endTime = endTimeByServiceAppointmentId.get(serviceAppointmentIdByThreadId.get(thread.Id));
            } else if (interestedResourceIdByThreadId.containsKey(thread.Id)) {
                Id serviceAppointmentId = serviceAppointmentIdByInterestedResourceId.get(
                    interestedResourceIdByThreadId.get(thread.Id)
                );
                endTime = endTimeByServiceAppointmentId.get(serviceAppointmentId);
            } else if (requestIdByThreadId.containsKey(thread.Id)) {
                Id requestId = requestIdByThreadId.get(thread.Id);
                endTime = endTimeByRequestId.get(requestId);
                if (endTime == null) {
                    endTime = fallbackEndTimeByRequestId.get(requestId);
                }
            } else if (workOrderIdByThreadId.containsKey(thread.Id)) {
                Id workOrderId = workOrderIdByThreadId.get(thread.Id);
                endTime = endTimeByWorkOrderId.get(workOrderId);
                if (endTime == null) {
                    endTime = fallbackEndTimeByWorkOrderId.get(workOrderId);
                }
            }

            result.put(thread.Id, buildPolicy(thread.Id, endTime));
        }

        return result;
    }

    private static ReplyPolicy buildPolicy(Id threadId, Datetime endTime) {
        if (endTime == null) {
            return new ReplyPolicy(threadId, true, null, null);
        }
        Datetime replyClosedAt = endTime.addHours(REPLY_WINDOW_HOURS);
        return new ReplyPolicy(threadId, System.now() < replyClosedAt, replyClosedAt, endTime);
    }

    private static Map<Id, Datetime> getLatestServiceAppointmentEndByRequestId(Set<Id> requestIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        if (requestIds.isEmpty()) {
            return result;
        }

        for (ServiceAppointment serviceAppointment : [
            SELECT Id, HOT_Request__c, SchedEndTime, DueDate
            FROM ServiceAppointment
            WHERE HOT_Request__c IN :requestIds AND Status != 'Annul'
        ]) {
            Datetime endTime = getServiceAppointmentEnd(serviceAppointment);
            Id requestId = serviceAppointment.HOT_Request__c;
            if (endTime != null && (result.get(requestId) == null || endTime > result.get(requestId))) {
                result.put(requestId, endTime);
            }
        }
        return result;
    }

    private static Map<Id, Datetime> getLatestServiceAppointmentEndByWorkOrderId(Set<Id> workOrderIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        if (workOrderIds.isEmpty()) {
            return result;
        }

        for (ServiceAppointment serviceAppointment : [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId, SchedEndTime, DueDate
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds AND Status != 'Annul'
        ]) {
            Datetime endTime = getServiceAppointmentEnd(serviceAppointment);
            Id workOrderId = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            if (endTime != null && (result.get(workOrderId) == null || endTime > result.get(workOrderId))) {
                result.put(workOrderId, endTime);
            }
        }
        return result;
    }

    private static Map<Id, Datetime> getEndByServiceAppointmentId(Set<Id> serviceAppointmentIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        if (serviceAppointmentIds.isEmpty()) {
            return result;
        }

        for (ServiceAppointment serviceAppointment : [
            SELECT Id, SchedEndTime, DueDate
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds AND Status != 'Annul'
        ]) {
            Datetime endTime = getServiceAppointmentEnd(serviceAppointment);
            if (endTime != null) {
                result.put(serviceAppointment.Id, endTime);
            }
        }
        return result;
    }

    private static Map<Id, Id> getServiceAppointmentIdByInterestedResourceId(Set<Id> interestedResourceIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        if (interestedResourceIds.isEmpty()) {
            return result;
        }

        for (HOT_InterestedResource__c interestedResource : [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE Id IN :interestedResourceIds
        ]) {
            result.put(interestedResource.Id, interestedResource.ServiceAppointment__c);
        }
        return result;
    }

    private static Map<Id, Datetime> getFallbackEndByRequestId(Set<Id> requestIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        if (requestIds.isEmpty()) {
            return result;
        }

        for (HOT_Request__c request : [SELECT Id, EndTime__c FROM HOT_Request__c WHERE Id IN :requestIds]) {
            if (request.EndTime__c != null) {
                result.put(request.Id, request.EndTime__c);
            }
        }
        return result;
    }

    private static Map<Id, Datetime> getFallbackEndByWorkOrderId(Set<Id> workOrderIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        if (workOrderIds.isEmpty()) {
            return result;
        }

        for (WorkOrder workOrder : [SELECT Id, EndDate FROM WorkOrder WHERE Id IN :workOrderIds]) {
            if (workOrder.EndDate != null) {
                result.put(workOrder.Id, workOrder.EndDate);
            }
        }
        return result;
    }

    private static Datetime getServiceAppointmentEnd(ServiceAppointment serviceAppointment) {
        return serviceAppointment.SchedEndTime != null ? serviceAppointment.SchedEndTime : serviceAppointment.DueDate;
    }
}
