public without sharing class HOT_WOInterpreterThreadService {
    private static final String INTERPRETER_THREAD_TYPE = 'HOT_TOLK-FORMIDLER';

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
        List<Result> results = initializeResults(reqs);
        if (reqs == null || reqs.isEmpty()) {
            return results;
        }

        Set<Id> workOrderIds = collectWorkOrderIds(reqs);
        if (workOrderIds.isEmpty()) {
            return results;
        }

        Map<Id, WorkOrder> workOrdersById = getWorkOrders(workOrderIds);
        Map<Id, Map<Id, Id>> saIdByWorkOrderAndServiceResource = getInterpreterTargets(workOrderIds);
        Map<Id, ServiceResource> serviceResourcesById = getServiceResources(saIdByWorkOrderAndServiceResource);
        Map<Id, Id> workOrderIdByServiceAppointmentId = getWorkOrderIdByServiceAppointmentId(
            saIdByWorkOrderAndServiceResource
        );
        Map<Id, Map<String, Thread__c>> existingThreadsByWorkOrder = getExistingThreadsByWorkOrder(
            workOrderIds,
            workOrderIdByServiceAppointmentId
        );

        Id threadRecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        List<Thread__c> threadsToInsert = new List<Thread__c>();
        Map<Integer, List<Thread__c>> threadsByReqIndex = new Map<Integer, List<Thread__c>>();

        for (Integer i = 0; i < reqs.size(); i++) {
            Input req = reqs[i];
            Result result = results[i];

            if (!validateReq(req, result, workOrdersById)) {
                continue;
            }

            Map<Id, Id> saIdByServiceResource = saIdByWorkOrderAndServiceResource.get(req.workOrderId);
            if (saIdByServiceResource == null || saIdByServiceResource.isEmpty()) {
                result.statusMessage = 'No interpreters found on Work Order';
                continue;
            }

            if (!existingThreadsByWorkOrder.containsKey(req.workOrderId)) {
                existingThreadsByWorkOrder.put(req.workOrderId, new Map<String, Thread__c>());
            }

            Map<String, Thread__c> threadByKey = existingThreadsByWorkOrder.get(req.workOrderId);
            List<Thread__c> threadsForRequest = new List<Thread__c>();
            WorkOrder workOrder = workOrdersById.get(req.workOrderId);

            for (Id serviceResourceId : saIdByServiceResource.keySet()) {
                ServiceResource serviceResource = serviceResourcesById.get(serviceResourceId);
                if (serviceResource == null) {
                    continue;
                }

                String threadKey = getThreadKey(serviceResource.Id);
                Thread__c thread = threadByKey.get(threadKey);

                if (thread == null) {
                    thread = buildInterpreterThread(
                        workOrder,
                        serviceResource,
                        saIdByServiceResource.get(serviceResourceId),
                        threadRecordTypeId
                    );
                    threadsToInsert.add(thread);
                    threadByKey.put(threadKey, thread);
                    result.createdThreadCount++;
                }

                threadsForRequest.add(thread);
            }

            if (threadsForRequest.isEmpty()) {
                result.statusMessage = 'No interpreters found on Work Order';
                continue;
            }

            result.interpreterCount = threadsForRequest.size();
            threadsByReqIndex.put(i, threadsForRequest);
        }

        if (!threadsToInsert.isEmpty()) {
            insert threadsToInsert;
        }

        createMessages(reqs, results, threadsByReqIndex);
        return results;
    }

    private static List<Result> initializeResults(List<Input> reqs) {
        List<Result> results = new List<Result>();
        if (reqs == null) {
            return results;
        }

        for (Input req : reqs) {
            Result result = new Result();
            result.workOrderId = req != null ? req.workOrderId : null;
            result.interpreterCount = 0;
            result.createdThreadCount = 0;
            result.messageCount = 0;
            result.statusMessage = 'No action';
            results.add(result);
        }
        return results;
    }

    private static Set<Id> collectWorkOrderIds(List<Input> reqs) {
        Set<Id> workOrderIds = new Set<Id>();
        for (Input req : reqs) {
            if (req != null && req.workOrderId != null) {
                workOrderIds.add(req.workOrderId);
            }
        }
        return workOrderIds;
    }

    private static Map<Id, WorkOrder> getWorkOrders(Set<Id> workOrderIds) {
        return new Map<Id, WorkOrder>(
            [
                SELECT Id, Subject, HOT_Request__r.Dispatcher__c, HOT_Request__r.Account__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ]
        );
    }

    private static Map<Id, Map<Id, Id>> getInterpreterTargets(Set<Id> workOrderIds) {
        Map<Id, Map<Id, Id>> saIdByWorkOrderAndServiceResource = new Map<Id, Map<Id, Id>>();

        for (ServiceAppointment serviceAppointment : [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds AND HOT_ServiceResource__c != NULL
        ]) {
            addInterpreterTarget(
                saIdByWorkOrderAndServiceResource,
                serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                serviceAppointment.HOT_ServiceResource__c,
                serviceAppointment.Id
            );
        }

        for (AssignedResource assignedResource : [
            SELECT ServiceResourceId, ServiceAppointmentId, ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
            FROM AssignedResource
            WHERE ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId IN :workOrderIds AND ServiceResourceId != NULL
        ]) {
            addInterpreterTarget(
                saIdByWorkOrderAndServiceResource,
                assignedResource.ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                assignedResource.ServiceResourceId,
                assignedResource.ServiceAppointmentId
            );
        }

        return saIdByWorkOrderAndServiceResource;
    }

    private static void addInterpreterTarget(
        Map<Id, Map<Id, Id>> saIdByWorkOrderAndServiceResource,
        Id workOrderId,
        Id serviceResourceId,
        Id serviceAppointmentId
    ) {
        if (workOrderId == null || serviceResourceId == null) {
            return;
        }

        if (!saIdByWorkOrderAndServiceResource.containsKey(workOrderId)) {
            saIdByWorkOrderAndServiceResource.put(workOrderId, new Map<Id, Id>());
        }

        Map<Id, Id> saIdByServiceResource = saIdByWorkOrderAndServiceResource.get(workOrderId);
        if (!saIdByServiceResource.containsKey(serviceResourceId) || saIdByServiceResource.get(serviceResourceId) == null) {
            saIdByServiceResource.put(serviceResourceId, serviceAppointmentId);
        }
    }

    private static Map<Id, ServiceResource> getServiceResources(
        Map<Id, Map<Id, Id>> saIdByWorkOrderAndServiceResource
    ) {
        Set<Id> serviceResourceIds = new Set<Id>();
        for (Map<Id, Id> saIdByServiceResource : saIdByWorkOrderAndServiceResource.values()) {
            serviceResourceIds.addAll(saIdByServiceResource.keySet());
        }

        if (serviceResourceIds.isEmpty()) {
            return new Map<Id, ServiceResource>();
        }

        return new Map<Id, ServiceResource>(
            [
                SELECT Id, AccountId, RelatedRecordId, HOT_IsEmployedInterpreter__c
                FROM ServiceResource
                WHERE Id IN :serviceResourceIds
            ]
        );
    }

    private static Map<Id, Id> getWorkOrderIdByServiceAppointmentId(
        Map<Id, Map<Id, Id>> saIdByWorkOrderAndServiceResource
    ) {
        Map<Id, Id> workOrderIdByServiceAppointmentId = new Map<Id, Id>();
        for (Id workOrderId : saIdByWorkOrderAndServiceResource.keySet()) {
            for (Id serviceAppointmentId : saIdByWorkOrderAndServiceResource.get(workOrderId).values()) {
                if (serviceAppointmentId != null && !workOrderIdByServiceAppointmentId.containsKey(serviceAppointmentId)) {
                    workOrderIdByServiceAppointmentId.put(serviceAppointmentId, workOrderId);
                }
            }
        }
        return workOrderIdByServiceAppointmentId;
    }

    private static Map<Id, Map<String, Thread__c>> getExistingThreadsByWorkOrder(
        Set<Id> workOrderIds,
        Map<Id, Id> workOrderIdByServiceAppointmentId
    ) {
        Map<Id, Map<String, Thread__c>> threadByWorkOrderAndKey = new Map<Id, Map<String, Thread__c>>();
        Set<Id> serviceAppointmentIds = new Set<Id>(workOrderIdByServiceAppointmentId.keySet());

        for (Thread__c thread : [
            SELECT
                Id,
                HOT_WorkOrder__c,
                HOT_ServiceAppointment__c,
                CRM_Related_Object__c,
                HOT_ServiceResource__c,
                CRM_Account__c,
                CRM_Thread_Type__c,
                CRM_isActive__c
            FROM Thread__c
            WHERE
                CRM_Thread_Type__c = :INTERPRETER_THREAD_TYPE
                AND (HOT_WorkOrder__c IN :workOrderIds
                OR HOT_ServiceAppointment__c IN :serviceAppointmentIds
                OR CRM_Related_Object__c IN :serviceAppointmentIds)
        ]) {
            Id workOrderId = resolveWorkOrderId(thread, workOrderIdByServiceAppointmentId);
            if (workOrderId == null) {
                continue;
            }

            if (!threadByWorkOrderAndKey.containsKey(workOrderId)) {
                threadByWorkOrderAndKey.put(workOrderId, new Map<String, Thread__c>());
            }

            String threadKey = getThreadKey(thread.HOT_ServiceResource__c);
            if (threadKey != null) {
                threadByWorkOrderAndKey.get(workOrderId).put(threadKey, thread);
            }
        }

        return threadByWorkOrderAndKey;
    }

    private static Id resolveWorkOrderId(Thread__c thread, Map<Id, Id> workOrderIdByServiceAppointmentId) {
        if (thread.HOT_WorkOrder__c != null) {
            return thread.HOT_WorkOrder__c;
        }

        if (thread.HOT_ServiceAppointment__c != null) {
            return workOrderIdByServiceAppointmentId.get(thread.HOT_ServiceAppointment__c);
        }

        return null;
    }

    private static Boolean validateReq(Input req, Result result, Map<Id, WorkOrder> workOrdersById) {
        if (req == null || req.workOrderId == null) {
            result.statusMessage = 'Missing Work Order Id';
            return false;
        }
        if (String.isBlank(req.messageText)) {
            result.statusMessage = 'Missing message text';
            return false;
        }
        if (!workOrdersById.containsKey(req.workOrderId)) {
            result.statusMessage = 'Work Order not found';
            return false;
        }
        return true;
    }

    private static Thread__c buildInterpreterThread(
        WorkOrder workOrder,
        ServiceResource serviceResource,
        Id serviceAppointmentId,
        Id threadRecordTypeId
    ) {
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = threadRecordTypeId;
        thread.Name = 'SAMTALE MED TOLK: ' + workOrder.Subject;
        thread.CRM_Related_Object__c = serviceAppointmentId != null ? serviceAppointmentId : workOrder.Id;
        thread.HOT_ServiceAppointment__c = serviceAppointmentId;
        thread.HOT_WorkOrder__c = workOrder.Id;
        thread.CRM_Thread_Type__c = INTERPRETER_THREAD_TYPE;
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

        return thread;
    }

    private static void createMessages(
        List<Input> reqs,
        List<Result> results,
        Map<Integer, List<Thread__c>> threadsByReqIndex
    ) {
        List<Message__c> messagesToInsert = new List<Message__c>();

        for (Integer index : threadsByReqIndex.keySet()) {
            Input req = reqs[index];
            Result result = results[index];

            for (Thread__c thread : threadsByReqIndex.get(index)) {
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
    }

    private static String getThreadKey(Id serviceResourceId) {
        if (serviceResourceId == null) {
            return null;
        }
        return 'SR:' + serviceResourceId;
    }
}
