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

        public Result(Input req) {
            this.workOrderId = req != null ? req.workOrderId : null;
            this.interpreterCount = 0;
            this.createdThreadCount = 0;
            this.messageCount = 0;
            this.statusMessage = 'No action';
        }
    }

    @InvocableMethod(label='Create Missing Interpreter Threads And Broadcast Message')
    public static List<Result> sendMessageToInterpreters(List<Input> reqs) {
        HOT_WOInterpreterThreadService threadService = new HOT_WOInterpreterThreadService(reqs);
        return threadService.process();
    }

    private List<Input> reqs;
    private List<Result> results;
    private Set<Id> workOrderIds;
    private Map<Id, WorkOrder> workOrdersById;
    private Map<Id, Map<Id, Id>> saIdByWorkOrderAndServiceResource;
    private Map<Id, ServiceResource> serviceResourcesById;
    private Map<Id, Id> workOrderIdByServiceAppointmentId;
    private Map<Id, Thread__c> existingThreadsByServiceAppointment;

    private Id threadRecordTypeId;
    private List<Thread__c> threadsToInsert;
    private Map<Integer, List<Thread__c>> threadsByReqIndex;

    public HOT_WOInterpreterThreadService(List<Input> reqs) {
        this.reqs = reqs;
        this.results = new List<Result>();
        this.workOrderIds = new Set<Id>();
        this.threadsToInsert = new List<Thread__c>();
        this.threadsByReqIndex = new Map<Integer, List<Thread__c>>();
        this.threadRecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
    }

    public List<Result> process() {
        initializeResults();

        if (this.reqs == null || this.reqs.isEmpty()) {
            return this.results;
        }

        collectWorkOrderIds();
        if (this.workOrderIds.isEmpty()) {
            return this.results;
        }

        // Henter all nødvendig data og lagrer i instansvariablene
        loadData();

        // Klargjør tråder
        prepareThreads();

        // Sender meldinger
        sendMessages();

        return this.results;
    }

    private void initializeResults() {
        if (this.reqs == null)
            return;

        for (Input req : this.reqs) {
            this.results.add(new Result(req));
        }
    }

    private void collectWorkOrderIds() {
        for (Input req : this.reqs) {
            if (req != null && req.workOrderId != null) {
                this.workOrderIds.add(req.workOrderId);
            }
        }
    }

    private void loadData() {
        // Henter WorkOrders
        this.workOrdersById = new Map<Id, WorkOrder>(
            [
                SELECT Id, Subject, HOT_Request__r.Dispatcher__c, HOT_Request__r.Account__c
                FROM WorkOrder
                WHERE Id IN :this.workOrderIds
            ]
        );

        // Henter Interpreter Targets
        this.saIdByWorkOrderAndServiceResource = new Map<Id, Map<Id, Id>>();

        for (ServiceAppointment serviceAppointment : [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :this.workOrderIds AND HOT_ServiceResource__c != NULL
        ]) {
            addInterpreterTarget(
                serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                serviceAppointment.HOT_ServiceResource__c,
                serviceAppointment.Id
            );
        }

        for (AssignedResource assignedResource : [
            SELECT ServiceResourceId, ServiceAppointmentId, ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
            FROM AssignedResource
            WHERE
                ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId IN :this.workOrderIds
                AND ServiceResourceId != NULL
        ]) {
            addInterpreterTarget(
                assignedResource.ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
                assignedResource.ServiceResourceId,
                assignedResource.ServiceAppointmentId
            );
        }

        // Setter opp ServiceResources og Mapping for Appointments
        loadServiceResources();
        loadWorkOrderIdByServiceAppointmentId();

        // Henter eksisterende tråder
        loadExistingThreadsByServiceAppointment();
    }

    private void addInterpreterTarget(Id workOrderId, Id serviceResourceId, Id serviceAppointmentId) {
        if (!this.saIdByWorkOrderAndServiceResource.containsKey(workOrderId)) {
            this.saIdByWorkOrderAndServiceResource.put(workOrderId, new Map<Id, Id>());
        }

        Map<Id, Id> saIdByServiceResource = this.saIdByWorkOrderAndServiceResource.get(workOrderId);
        if (
            !saIdByServiceResource.containsKey(serviceResourceId) ||
            saIdByServiceResource.get(serviceResourceId) == null
        ) {
            saIdByServiceResource.put(serviceResourceId, serviceAppointmentId);
        }
    }

    private void loadServiceResources() {
        Set<Id> serviceResourceIds = new Set<Id>();
        for (Map<Id, Id> saIdByServiceResource : this.saIdByWorkOrderAndServiceResource.values()) {
            serviceResourceIds.addAll(saIdByServiceResource.keySet());
        }

        if (serviceResourceIds.isEmpty()) {
            this.serviceResourcesById = new Map<Id, ServiceResource>();
            return;
        }

        this.serviceResourcesById = new Map<Id, ServiceResource>(
            [
                SELECT Id, AccountId, RelatedRecordId, HOT_IsEmployedInterpreter__c
                FROM ServiceResource
                WHERE Id IN :serviceResourceIds
            ]
        );
    }

    private void loadWorkOrderIdByServiceAppointmentId() {
        this.workOrderIdByServiceAppointmentId = new Map<Id, Id>();
        for (Id workOrderId : this.saIdByWorkOrderAndServiceResource.keySet()) {
            for (Id serviceAppointmentId : this.saIdByWorkOrderAndServiceResource.get(workOrderId).values()) {
                if (
                    serviceAppointmentId != null &&
                    !this.workOrderIdByServiceAppointmentId.containsKey(serviceAppointmentId)
                ) {
                    this.workOrderIdByServiceAppointmentId.put(serviceAppointmentId, workOrderId);
                }
            }
        }
    }

    private void loadExistingThreadsByServiceAppointment() {
        this.existingThreadsByServiceAppointment = new Map<Id, Thread__c>();
        Set<Id> serviceAppointmentIds = new Set<Id>(this.workOrderIdByServiceAppointmentId.keySet());
        if (serviceAppointmentIds.isEmpty()) {
            return;
        }

        for (Thread__c thread : [
            SELECT Id, CRM_Related_Object__c, CRM_Account__c, CRM_Thread_Type__c, CRM_isActive__c
            FROM Thread__c
            WHERE CRM_Thread_Type__c = :INTERPRETER_THREAD_TYPE AND CRM_Related_Object__c IN :serviceAppointmentIds
        ]) {
            this.existingThreadsByServiceAppointment.put(thread.CRM_Related_Object__c, thread);
        }
    }

    private void prepareThreads() {
        for (Integer i = 0; i < this.reqs.size(); i++) {
            Input req = this.reqs[i];
            Result result = this.results[i];

            if (!validateReq(req, result)) {
                continue;
            }

            Map<Id, Id> saIdByServiceResource = this.saIdByWorkOrderAndServiceResource.get(req.workOrderId);
            if (saIdByServiceResource == null || saIdByServiceResource.isEmpty()) {
                result.statusMessage = 'No interpreters found on Work Order';
                continue;
            }

            List<Thread__c> threadsForRequest = new List<Thread__c>();
            WorkOrder workOrder = this.workOrdersById.get(req.workOrderId);

            for (Id serviceResourceId : saIdByServiceResource.keySet()) {
                ServiceResource serviceResource = this.serviceResourcesById.get(serviceResourceId);
                if (serviceResource == null) {
                    continue;
                }

                Id serviceAppointmentId = saIdByServiceResource.get(serviceResourceId);
                Thread__c thread = serviceAppointmentId == null
                    ? null
                    : this.existingThreadsByServiceAppointment.get(serviceAppointmentId);

                if (thread == null) {
                    thread = buildInterpreterThread(workOrder, serviceResource, serviceAppointmentId);
                    this.threadsToInsert.add(thread);
                    if (serviceAppointmentId != null) {
                        this.existingThreadsByServiceAppointment.put(serviceAppointmentId, thread);
                    }
                    result.createdThreadCount++;
                }

                threadsForRequest.add(thread);
            }

            if (threadsForRequest.isEmpty()) {
                result.statusMessage = 'No interpreters found on Work Order';
                continue;
            }

            result.interpreterCount = threadsForRequest.size();
            this.threadsByReqIndex.put(i, threadsForRequest);
        }

        if (!this.threadsToInsert.isEmpty()) {
            insert this.threadsToInsert;
        }
    }

    private Boolean validateReq(Input req, Result result) {
        if (req == null || req.workOrderId == null) {
            result.statusMessage = 'Missing Work Order Id';
            return false;
        }
        if (String.isBlank(req.messageText)) {
            result.statusMessage = 'Missing message text';
            return false;
        }
        if (!this.workOrdersById.containsKey(req.workOrderId)) {
            result.statusMessage = 'Work Order not found';
            return false;
        }
        return true;
    }

    private Thread__c buildInterpreterThread(
        WorkOrder workOrder,
        ServiceResource serviceResource,
        Id serviceAppointmentId
    ) {
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = this.threadRecordTypeId;
        thread.Name = HOT_ThreadHandler.threadSubjectMaker('SAMTALE MED TOLK: ' + workOrder.Subject); // Avkorter teksten med substring og legger til ... hvis navnet blir for langt.
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

        return thread;
    }

    private void sendMessages() {
        List<Message__c> messagesToInsert = new List<Message__c>();

        for (Integer index : this.threadsByReqIndex.keySet()) {
            Input req = this.reqs[index];
            Result result = this.results[index];

            for (Thread__c thread : this.threadsByReqIndex.get(index)) {
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
}
