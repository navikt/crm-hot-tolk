public without sharing class HOT_WOInterpreterThreadService {
    public class Input {
        @InvocableVariable(label='Work Order Id' required=true)
        public Id workOrderId;

        @InvocableVariable(label='Message Text' required=true)
        public String messageText;

        @InvocableVariable(label='From Contact Id')
        public Id fromContactId;
    }

    public class Result {
        @InvocableVariable(label='Work Order Id')
        public Id workOrderId;

        @InvocableVariable(label='Interpreters Found')
        public Integer interpreterCount;

        @InvocableVariable(label='Created Threads')
        public Integer createdThreadCount;

        @InvocableVariable(label='Messages Created')
        public Integer messageCount;

        @InvocableVariable(label='Status Message')
        public String statusMessage;
    }

    @InvocableMethod(label='Create Missing Interpreter Threads And Broadcast Message')
    public static List<Result> sendMessageToInterpreters(List<Input> reqs) {
        List<Result> results = new List<Result>();
        if (reqs == null) {
            return results;
        }

        Set<Id> workOrderIds = new Set<Id>();
        for (Integer i = 0; i < reqs.size(); i++) {
            Input req = reqs[i];
            Result result = new Result();
            result.interpreterCount = 0;
            result.createdThreadCount = 0;
            result.messageCount = 0;
            result.statusMessage = 'No action';

            if (req != null) {
                result.workOrderId = req.workOrderId;
                if (req.workOrderId != null) {
                    workOrderIds.add(req.workOrderId);
                }
            }
            results.add(result);
        }

        if (workOrderIds.isEmpty()) {
            return results;
        }

        Map<Id, WorkOrder> workOrderById = new Map<Id, WorkOrder>(
            [
                SELECT Id, Subject, HOT_Request__r.Dispatcher__c, HOT_Request__r.Account__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ]
        );

        Map<Id, Set<Id>> workOrderToServiceResourceIds = new Map<Id, Set<Id>>();

        for (ServiceAppointment serviceAppointment : [
            SELECT HOT_WorkOrderLineItem__r.WorkOrderId, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds AND HOT_ServiceResource__c != NULL
        ]) {
            addServiceResource(
                workOrderToServiceResourceIds,
                serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                serviceAppointment.HOT_ServiceResource__c
            );
        }

        for (AssignedResource assignedResource : [
            SELECT ServiceResourceId, ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
            FROM AssignedResource
            WHERE ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds
        ]) {
            addServiceResource(
                workOrderToServiceResourceIds,
                assignedResource.ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                assignedResource.ServiceResourceId
            );
        }

        Set<Id> allServiceResourceIds = new Set<Id>();
        for (Set<Id> serviceResourceIds : workOrderToServiceResourceIds.values()) {
            allServiceResourceIds.addAll(serviceResourceIds);
        }

        Map<Id, ServiceResource> serviceResourceById = new Map<Id, ServiceResource>();
        if (!allServiceResourceIds.isEmpty()) {
            serviceResourceById = new Map<Id, ServiceResource>(
                [
                    SELECT Id, AccountId, RelatedRecordId, HOT_IsEmployedInterpreter__c
                    FROM ServiceResource
                    WHERE Id IN :allServiceResourceIds
                ]
            );
        }

        Map<Id, Map<Id, ServiceResource>> interpretersByWorkOrder = new Map<Id, Map<Id, ServiceResource>>();
        for (Id workOrderId : workOrderToServiceResourceIds.keySet()) {
            Map<Id, ServiceResource> interpretersForWorkOrder = new Map<Id, ServiceResource>();
            for (Id serviceResourceId : workOrderToServiceResourceIds.get(workOrderId)) {
                ServiceResource serviceResource = serviceResourceById.get(serviceResourceId);
                if (serviceResource != null) {
                    interpretersForWorkOrder.put(serviceResourceId, serviceResource);
                }
            }
            interpretersByWorkOrder.put(workOrderId, interpretersForWorkOrder);
        }

        Map<Id, Map<String, Thread__c>> threadsByWorkOrderAndKey = new Map<Id, Map<String, Thread__c>>();
        for (Thread__c thread : [
            SELECT
                Id,
                HOT_WorkOrder__c,
                CRM_Related_Object__c,
                HOT_ServiceResource__c,
                CRM_Account__c,
                CRM_Thread_Type__c,
                CRM_isActive__c
            FROM Thread__c
            WHERE
                CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
                AND (HOT_WorkOrder__c IN :workOrderIds
                OR CRM_Related_Object__c IN :workOrderIds)
        ]) {
            Id workOrderId = thread.HOT_WorkOrder__c != null ? thread.HOT_WorkOrder__c : thread.CRM_Related_Object__c;
            if (workOrderId == null) {
                continue;
            }
            if (!threadsByWorkOrderAndKey.containsKey(workOrderId)) {
                threadsByWorkOrderAndKey.put(workOrderId, new Map<String, Thread__c>());
            }
            threadsByWorkOrderAndKey.get(workOrderId)
                .put(getThreadKey(thread.HOT_ServiceResource__c, thread.CRM_Account__c), thread);
        }

        Id threadRecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        List<Thread__c> threadsToInsert = new List<Thread__c>();
        Map<Integer, List<Thread__c>> requestIndexToThreads = new Map<Integer, List<Thread__c>>();

        for (Integer i = 0; i < reqs.size(); i++) {
            Input req = reqs[i];
            Result result = results[i];

            if (req == null || req.workOrderId == null) {
                result.statusMessage = 'Missing Work Order Id';
                continue;
            }
            if (String.isBlank(req.messageText)) {
                result.statusMessage = 'Missing message text';
                continue;
            }
            if (!workOrderById.containsKey(req.workOrderId)) {
                result.statusMessage = 'Work Order not found';
                continue;
            }

            Map<Id, ServiceResource> interpreters = interpretersByWorkOrder.get(req.workOrderId);
            if (interpreters == null || interpreters.isEmpty()) {
                result.statusMessage = 'No interpreters found on Work Order';
                continue;
            }

            result.interpreterCount = interpreters.size();

            if (!threadsByWorkOrderAndKey.containsKey(req.workOrderId)) {
                threadsByWorkOrderAndKey.put(req.workOrderId, new Map<String, Thread__c>());
            }

            WorkOrder workOrder = workOrderById.get(req.workOrderId);
            Map<String, Thread__c> threadByKey = threadsByWorkOrderAndKey.get(req.workOrderId);
            List<Thread__c> threadsForMessage = new List<Thread__c>();

            for (ServiceResource serviceResource : interpreters.values()) {
                String threadKey = getThreadKey(serviceResource.Id, serviceResource.AccountId);
                Thread__c thread = threadByKey.get(threadKey);
                if (thread == null && serviceResource.AccountId != null) {
                    // Backward-compatibility: reuse older account-only threads if they exist.
                    thread = threadByKey.get(getThreadKey(null, serviceResource.AccountId));
                    if (thread != null) {
                        threadByKey.put(threadKey, thread);
                    }
                }

                if (thread == null) {
                    thread = new Thread__c();
                    thread.RecordTypeId = threadRecordTypeId;
                    thread.Name = 'SAMTALE MED TOLK: ' + workOrder.Subject;
                    thread.CRM_Related_Object__c = workOrder.Id;
                    thread.HOT_WorkOrder__c = workOrder.Id;
                    thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                    thread.HOT_ServiceResource__c = serviceResource.Id;
                    thread.CRM_Account__c = serviceResource.AccountId;
                    thread.HOT_Account__c = workOrder.HOT_Request__r.Account__c;
                    thread.HOT_Dispatcher__c = workOrder.HOT_Request__r.Dispatcher__c;
                    thread.HOT_Title__c = workOrder.Subject;
                    thread.HOT_IsEmployeeThread__c = serviceResource.HOT_IsEmployedInterpreter__c;
                    thread.CRM_isActive__c = true;

                    if (serviceResource.RelatedRecordId != null) {
                        thread.HOT_ParticipantIds__c = serviceResource.RelatedRecordId;
                    }

                    threadsToInsert.add(thread);
                    threadByKey.put(threadKey, thread);
                    result.createdThreadCount++;
                }

                threadsForMessage.add(thread);
            }

            requestIndexToThreads.put(i, threadsForMessage);
        }

        if (!threadsToInsert.isEmpty()) {
            insert threadsToInsert;
        }

        List<Message__c> messagesToInsert = new List<Message__c>();
        for (Integer i : requestIndexToThreads.keySet()) {
            Input req = reqs[i];
            Result result = results[i];
            List<Thread__c> threads = requestIndexToThreads.get(i);

            for (Thread__c thread : threads) {
                if (thread.CRM_isActive__c == false) {
                    continue;
                }

                messagesToInsert.add(HOT_MessageHelper.createMessages(thread, req.messageText, req.fromContactId));
                result.messageCount++;
            }

            result.statusMessage = 'Processed';
        }

        if (!messagesToInsert.isEmpty()) {
            insert messagesToInsert;
        }

        return results;
    }

    private static void addServiceResource(
        Map<Id, Set<Id>> workOrderToServiceResourceIds,
        Id workOrderId,
        Id serviceResourceId
    ) {
        if (workOrderId == null || serviceResourceId == null) {
            return;
        }

        if (!workOrderToServiceResourceIds.containsKey(workOrderId)) {
            workOrderToServiceResourceIds.put(workOrderId, new Set<Id>());
        }

        workOrderToServiceResourceIds.get(workOrderId).add(serviceResourceId);
    }

    private static String getThreadKey(Id serviceResourceId, Id accountId) {
        if (serviceResourceId != null) {
            return 'SR:' + serviceResourceId;
        }
        return 'ACC:' + accountId;
    }
}
