public without sharing class HOT_ThreadParticipants_dev {
    public class Participant {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String role;
        @AuraEnabled
        public Id userId;
        @AuraEnabled
        public Boolean hasRead = false;
        public Participant(ServiceAppointment sa) {
            this.name = formatName(sa.HOT_ServiceResource__r.Name);
            this.role = 'Tolk';
            this.userId = sa.HOT_ServiceResource__r.RelatedRecordId;
        }
        public Participant(WorkOrder wo, User user) {
            this.name = formatName(wo.Account.Name);
            this.role = 'Tolkebruker';
            this.userId = user.Id;
        }
        public Participant(HOT_InterestedResource__c ir) {
            this.name = formatName(ir.ServiceResource__r.Name);
            this.role = 'Tolk';
            this.userId = ir.ServiceResource__r.RelatedRecordId;
        }
        public Participant(HOT_WageClaim__c wc) {
            this.name = formatName(wc.ServiceResource__r.Name);
            this.role = 'Tolk';
            this.userId = wc.ServiceResource__r.RelatedRecordId;
        }
        public Participant() {
        }
        public Participant(String name) {
            this.name = formatName(name);
        }
        public Participant(String name, String role, Id userId) {
            this.name = formatName(name);
            this.role = role;
            this.userId = userId;
        }
        public Participant setHasRead() {
            this.hasRead = true;
            return this;
        }
    }

    Set<Id> threadIds = new Set<Id>();
    List<Thread__c> threads = new List<Thread__c>();
    Map<Id, List<Participant>> participantsByThreadId = new Map<Id, List<Participant>>();
    Map<Id, Set<Id>> threadIdsByRelatedObjectId = new Map<Id, Set<Id>>();
    Id relatedObjectId;
    List<String> threadTypesOfInterest;
    public HOT_ThreadParticipants_dev(Id threadId) {
        this.threadIds.add(threadId);
        this.getThreads();
        this.mapThreadIdsByRelatedObjectIds();
        this.initParticipantsByThreadId();
    }
    public HOT_ThreadParticipants_dev(List<Id> threadIds) {
        this.threadIds = new Set<Id>(threadIds);
        this.getThreads();
        this.mapThreadIdsByRelatedObjectIds();
        this.initParticipantsByThreadId();
    }
    public HOT_ThreadParticipants_dev(Thread__c thread) {
        this.threadIds.add(thread.Id);
        this.threads.add(thread);
        this.mapThreadIdsByRelatedObjectIds();
        this.initParticipantsByThreadId();
    }
    public HOT_ThreadParticipants_dev(List<Thread__c> threads) {
        this.threadIds = new Map<Id, Thread__c>(threads).keySet();
        this.threads = threads;
        this.mapThreadIdsByRelatedObjectIds();
        this.initParticipantsByThreadId();
    }
    public HOT_ThreadParticipants_dev(Id relatedObjectId, List<String> threadTypesOfInterest) {
        this.relatedObjectId = relatedObjectId;
        this.threadTypesOfInterest = threadTypesOfInterest;
        this.getThreadsForRelatedObject();
        this.threadIds = new Map<Id, Thread__c>(this.threads).keySet();
        this.mapThreadIdsByRelatedObjectIds();
        this.initParticipantsByThreadId();
    }
    private void getThreads() {
        this.threads = [
            SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c, HOT_IsEmployeeThread__c, HOT_Thread_read_by__c
            FROM Thread__c
            WHERE Id IN :threadIds
        ];
    }
    private void getThreadsForRelatedObject() {
        this.threads = [
            SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c, HOT_IsEmployeeThread__c, HOT_Thread_read_by__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :this.relatedObjectId AND CRM_Thread_Type__c IN :this.threadTypesOfInterest
        ];
    }

    private void mapThreadIdsByRelatedObjectIds() {
        for (Thread__c thread : threads) {
            if (this.threadIdsByRelatedObjectId.get(thread.CRM_Related_Object__c) == null) {
                this.threadIdsByRelatedObjectId.put(thread.CRM_Related_Object__c, new Set<Id>());
            }
            this.threadIdsByRelatedObjectId.get(thread.CRM_Related_Object__c).add(thread.Id);
        }
    }

    private void initParticipantsByThreadId() {
        for (Id threadId : this.threadIds) {
            this.participantsByThreadId.put(threadId, new List<Participant>());
        }
    }
    private HOT_ThreadParticipants_dev getAssignedServiceResourceParticipants() {
        for (ServiceAppointment sa : [
            SELECT
                Id,
                HOT_ServiceResource__r.RelatedRecordId,
                HOT_ServiceResource__r.Name,
                HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId IN :this.threadIdsByRelatedObjectId.keySet()
                AND HOT_ServiceResource__r.Name != NULL
        ]) {
            for (Id threadId : this.threadIdsByRelatedObjectId.get(sa.HOT_WorkOrderLineItem__r.WorkOrderId)) {
                this.participantsByThreadId.get(threadId).add(new Participant(sa));
            }
        }
        return this;
    }
    @AuraEnabled(cacheable=true)
    public static List<Participant> getParticipants(String threadId) {
        List<Participant> participantList = new List<Participant>();
        Thread__c thread = [
            SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c, HOT_IsEmployeeThread__c, HOT_Thread_read_by__c
            FROM Thread__c
            WHERE Id = :threadId
        ];
        participantList.addAll(getAssignedServiceResources(thread));
        participantList.addAll(getAccountParticipants(thread));
        setReadStatus(participantList, thread);
        return participantList;
    }
    @AuraEnabled
    public static Map<Id, List<Participant>> getParticipantsByThreads(List<Id> threadIds) {
        try {
            return new HOT_ThreadParticipants_dev(threadIds)
                .getAssignedServiceResourceParticipants()
                .getRelatedObjectParticipants()
                .setReadStatus()
                .participantsByThreadId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Map<String, Map<Id, List<Participant>>> getParticipantsByRelatedObjectAndThreadTypes(
        Id relatedObjectId,
        List<String> threadTypesOfInterest
    ) {
        return new HOT_ThreadParticipants_dev(relatedObjectId, threadTypesOfInterest)
            .getAssignedServiceResourceParticipants()
            .getRelatedObjectParticipants()
            .setReadStatus()
            .getParticipantsByRelatedObjectAndThreadId();
    }
    private Map<String, Map<Id, List<Participant>>> getParticipantsByRelatedObjectAndThreadId() {
        Map<String, Map<Id, List<Participant>>> result = new Map<String, Map<Id, List<Participant>>>();
        for (String threadType : this.threadTypesOfInterest) {
            result.put(threadType, new Map<Id, List<Participant>>());
        }
        for (Id threadId : this.participantsByThreadId.keySet()) {
            result.get(new Map<Id, Thread__c>(this.threads).get(threadId).CRM_Thread_Type__c)
                .put(threadId, this.participantsByThreadId.get(threadId));
        }
        return result;
    }
    private static List<Participant> setReadStatus(List<Participant> participants, Thread__c thread) {
        Set<Id> userOrContactIds = new Set<Id>();
        if (!String.isBlank(thread.HOT_Thread_read_by__c)) {
            userOrContactIds.addAll(new List<Id>((List<Id>) thread.HOT_Thread_read_by__c.split(';')));
        }

        Boolean hasFormidler = false;
        Boolean hasResssurskontor = false;
        Set<Id> userIds = new Set<Id>();
        for (User u : [
            SELECT Id, Profile.Name
            FROM User
            WHERE ContactId IN :userOrContactIds OR Id IN :userOrContactIds
        ]) {
            userIds.add(u.Id);
            if (u.Profile.Name == 'HOT Tolk Formidler') {
                hasFormidler = true;
            }
            if (u.Profile.Name == 'HOT Tolk Saksbehandler') {
                hasResssurskontor = true;
            }
        }

        for (Participant p : participants) {
            if (userIds.contains(p.userId)) {
                p.setHasRead();
            } else if (p.userId == null && p.name == 'Formidler' && hasFormidler) {
                // Set Formidler as read for all users
                p.setHasRead();
            } else if (p.userId == null && p.name == 'Ressurskontor' && hasResssurskontor) {
                // Set Ressurskontor as read for all users
                p.setHasRead();
            }
        }
        return participants;
    }
    private Boolean hasObjectTypeRelations(String relatedObjectType) {
        for (Thread__c thread : this.threads) {
            if (String.valueOf(((Id) (thread.CRM_Related_Object__c)).getSObjectType()) == relatedObjectType) {
                return true;
            }
        }
        return false;
    }

    private HOT_ThreadParticipants_dev setReadStatus() {
        Map<Id, Set<Id>> userOrContactIdsByThreadId = new Map<Id, Set<Id>>();
        Set<Id> userOrContactIds = new Set<Id>();
        for (Thread__c thread : this.threads) {
            if (!String.isBlank(thread.HOT_Thread_read_by__c)) {
                Set<Id> threadUserOrContactIds = new Set<Id>((List<Id>) (thread.HOT_Thread_read_by__c.split(';')));
                userOrContactIds.addAll(threadUserOrContactIds);
                userOrContactIdsByThreadId.put(thread.Id, threadUserOrContactIds);
            }
        }
        if (userOrContactIds.size() == 0) {
            return this;
        }
        Map<Id, User> usersByUserId = new Map<Id, User>(
            [
                SELECT Id, ContactId, Profile.Name
                FROM User
                WHERE ContactId IN :userOrContactIds OR Id IN :userOrContactIds
            ]
        );
        Map<Id, User> usersByContactId = new Map<Id, User>();
        for (User u : usersByUserId.values()) {
            if (u.ContactId != null) {
                usersByContactId.put(u.ContactId, u);
            }
        }
        for (Id threadId : this.threadIds) {
            Map<Id, User> usersInThread = new Map<Id, User>();
            for (Id userOrContactId : userOrContactIdsByThreadId.get(threadId)) {
                if (usersByUserId.containsKey(userOrContactId)) {
                    usersInThread.put(userOrContactId, usersByUserId.get(userOrContactId));
                } else if (usersByContactId.containsKey(userOrContactId)) {
                    User u = usersByContactId.get(userOrContactId);
                    usersInThread.put(u.Id, u);
                }
            }
            Boolean hasFormidler = false;
            Boolean hasResssurskontor = false;
            for (User u : usersInThread.values()) {
                if (u.Profile.Name == 'HOT Tolk Formidler') {
                    hasFormidler = true;
                }
                if (u.Profile.Name == 'HOT Tolk Saksbehandler') {
                    hasResssurskontor = true;
                }
            }
            for (Participant p : this.participantsByThreadId.get(threadId)) {
                if (usersInThread.containsKey(p.userId)) {
                    p.setHasRead();
                } else if (p.userId == null) {
                    // Check for Formidler and Ressurskontor
                    if (p.name == 'Formidler' && hasFormidler) {
                        p.setHasRead();
                    } else if (p.name == 'Ressurskontor' && hasResssurskontor) {
                        p.setHasRead();
                    }
                }
            }
        }
        return this;
    }

    public static List<Participant> getAssignedServiceResources(Thread__c thread) {
        List<Participant> participants = new List<Participant>();

        for (ServiceAppointment sa : [
            SELECT
                Id,
                HOT_ServiceResource__r.RelatedRecordId,
                HOT_ServiceResource__r.Name,
                HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId = :thread.CRM_Related_Object__c
                AND HOT_ServiceResource__r.Name != NULL
        ]) {
            participants.add(new Participant(sa));
        }
        return participants;
    }

    private HOT_ThreadParticipants_dev getRelatedObjectParticipants() {
        if (this.hasObjectTypeRelations('WorkOrder')) {
            Set<Id> workOrdersOfInterest = new Set<Id>();
            for (Thread__c thread : this.threads) {
                if (
                    String.valueOf(((Id) thread.CRM_Related_Object__c).getSObjectType()) == 'WorkOrder' &&
                    thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK'
                ) {
                    workOrdersOfInterest.add(thread.CRM_Related_Object__c);
                }
            }
            if (workOrdersOfInterest.size() > 0) {
                this.getParticipantsFromWorkOrders(workOrdersOfInterest);
            }
        }
        if (this.hasObjectTypeRelations('ServiceAppointment')) {
            this.getParticipantsFromServiceAppointments();
        }
        if (this.hasObjectTypeRelations('HOT_InterestedResource__c')) {
            this.getParticipantsFromInterestedResources();
        }
        if (this.hasObjectTypeRelations('HOT_WageClaim__c')) {
            this.getParticipantsFromWageClaims();
        }
        if (this.hasObjectTypeRelations('HOT_Request__c')) {
            this.getParticipansFromRequests();
        }
        for (Thread__c thread : this.threads) {
            if (
                thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER'
            ) {
                this.participantsByThreadId.get(thread.Id).add(new Participant('Formidler'));
            }
            if (thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR') {
                this.participantsByThreadId.get(thread.Id).add(new Participant('Ressurskontor'));
            }
        }
        return this;
    }
    private void getParticipantsFromInterestedResources() {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, ServiceResource__r.Name, ServiceResource__r.RelatedRecordId
            FROM HOT_InterestedResource__c
            WHERE Id IN :this.threadIdsByRelatedObjectId.keySet()
        ];
        for (HOT_InterestedResource__c ir : interestedResources) {
            if (ir.ServiceResource__r.Name != null && ir.ServiceResource__r.RelatedRecordId != null) {
                for (Id threadId : this.threadIdsByRelatedObjectId.get(ir.Id)) {
                    this.participantsByThreadId.get(threadId).add(new Participant(ir));
                }
            }
        }
    }
    private void getParticipantsFromWageClaims() {
        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceResource__r.Name, ServiceResource__r.RelatedRecordId
            FROM HOT_WageClaim__c
            WHERE Id IN :this.threadIdsByRelatedObjectId.keySet()
        ];
        for (HOT_WageClaim__c wc : wageClaims) {
            if (wc.ServiceResource__r.Name != null && wc.ServiceResource__r.RelatedRecordId != null) {
                for (Id threadId : this.threadIdsByRelatedObjectId.get(wc.Id)) {
                    this.participantsByThreadId.get(threadId).add(new Participant(wc));
                }
            }
        }
    }
    private void getParticipansFromRequests() {
        List<HOT_Request__c> requests = [
            SELECT Id, Account__r.Name, Account__r.Id, Orderer__c, Orderer__r.Id, Orderer__r.Name, Account__c
            FROM HOT_Request__c
            WHERE Id IN :this.threadIdsByRelatedObjectId.keySet()
        ];
        Set<Id> userIds = new Set<Id>();
        for (HOT_Request__c req : requests) {
            userIds.add(req.Orderer__c);
            userIds.add(req.Account__c);
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :userIds];
        Map<Id, User> userByAccountId = new Map<Id, User>();
        for (User u : users) {
            userByAccountId.put(u.AccountId, u);
        }
        for (HOT_Request__c req : requests) {
            String participantName;
            String participantRole;
            Id participantUserId;

            for (Id threadId : this.threadIdsByRelatedObjectId.get(req.Id)) {
                Thread__c thread = new Map<Id, Thread__c>(this.threads).get(threadId);
                //this.threadsMap().get(this.threadIdsByRelatedObjectId(req.Id));
                // Sjekk type thread
                if (thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER') {
                    // Bruk Account
                    participantName = req.Account__r.Name;
                    participantRole = 'Tolkebruker';
                    User user = userByAccountId.get(req.Account__r.Id);
                    participantUserId = user != null ? user.Id : null;
                } else if (thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER') {
                    // Bruk Orderer
                    participantName = req.Orderer__r.Name;
                    participantRole = 'Bestiller';
                    User user = userByAccountId.get(req.Orderer__r.Id);
                    participantUserId = user != null ? user.Id : null;
                }
                // Legg til participant hvis navn og userId finnes
                if (participantName != null && participantUserId != null) {
                    this.participantsByThreadId.get(threadId)
                        .add(new Participant(participantName, participantRole, participantUserId));
                }
            }
        }
    }
    private void getParticipantsFromServiceAppointments() {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_ServiceResource__r.Name, HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE Id IN :this.threadIdsByRelatedObjectId.keySet()
        ];
        for (ServiceAppointment sa : serviceAppointments) {
            if (sa.HOT_ServiceResource__r.Name != null && sa.HOT_ServiceResource__r.RelatedRecordId != null) {
                for (Id threadId : this.threadIdsByRelatedObjectId.get(sa.Id)) {
                    this.participantsByThreadId.get(threadId).add(new Participant(sa));
                }
            }
        }
    }
    private void getParticipantsFromWorkOrders(Set<Id> workOrderIds) {
        List<WorkOrder> workOrders = [SELECT Id, AccountId, Account.Name FROM WorkOrder WHERE Id IN :workOrderIds];
        if (workOrders.size() == 0) {
            return;
        }
        Set<Id> accountIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            accountIds.add(wo.AccountId);
        }
        if (accountIds.size() == 0) {
            return;
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];
        if (users.size() == 0) {
            return;
        }
        Map<Id, User> usersByAccountId = new Map<Id, User>();
        for (User u : users) {
            usersByAccountId.put(u.AccountId, u);
        }
        for (WorkOrder wo : workOrders) {
            User user = usersByAccountId.get(wo.AccountId);
            if (user != null) {
                for (Id threadId : this.threadIdsByRelatedObjectId.get(wo.Id)) {
                    this.participantsByThreadId.get(threadId).add(new Participant(wo, user));
                }
            }
        }
    }

    public static List<Participant> getAccountParticipants(Thread__c thread) {
        List<Participant> participantList = new List<Participant>();
        Id search = thread.CRM_Related_Object__c;
        String objectType = String.valueOf(search.getsobjecttype());
        if (objectType == 'WorkOrder' && thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK') {
            WorkOrder workOrder = [
                SELECT Id, AccountId, Account.Name
                FROM WorkOrder
                WHERE Id = :thread.CRM_Related_Object__c
                LIMIT 1
            ];
            User user = [SELECT Id, AccountId FROM User WHERE AccountId = :workOrder.AccountId];

            if (workOrder.AccountId != null && user.Id != null) {
                participantList.add(new Participant(workOrder, user));
            }
        }
        if (objectType == 'ServiceAppointment') {
            ServiceAppointment serviceAppointment = [
                SELECT Id, AccountId, HOT_ServiceResource__r.Name, HOT_ServiceResource__r.RelatedRecordId
                FROM ServiceAppointment
                WHERE Id = :thread.CRM_Related_Object__c
                LIMIT 1
            ];
            if (
                serviceAppointment.HOT_ServiceResource__r.Name != null &&
                serviceAppointment.HOT_ServiceResource__r.RelatedRecordId != null
            ) {
                participantList.add(new Participant(serviceAppointment));
            }
        }
        if (objectType == 'HOT_InterestedResource__c') {
            HOT_InterestedResource__c interestedReource = [
                SELECT Id, ServiceResource__r.Name, ServiceResource__r.RelatedRecordId
                FROM HOT_InterestedResource__c
                WHERE Id = :thread.CRM_Related_Object__c
                LIMIT 1
            ];
            if (
                interestedReource.ServiceResource__r.Name != null &&
                interestedReource.ServiceResource__r.RelatedRecordId != null
            ) {
                participantList.add(new Participant(interestedReource));
            }
        }
        if (objectType == 'HOT_Wageclaim__c') {
            HOT_WageClaim__c wageClaim = [
                SELECT Id, ServiceResource__r.Name, ServiceResource__r.RelatedRecordId
                FROM HOT_WageClaim__c
                WHERE Id = :thread.CRM_Related_Object__c
                LIMIT 1
            ];
            if (wageClaim.ServiceResource__r.Name != null && wageClaim.ServiceResource__r.RelatedRecordId != null) {
                participantList.add(new Participant(wageClaim));
            }
        }
        if (objectType == 'HOT_Request__c') {
            HOT_Request__c request = [
                SELECT Id, Account__r.Name, Account__r.Id, Orderer__c, Orderer__r.Id, Orderer__r.Name, Account__c
                FROM HOT_Request__c
                WHERE Id = :thread.CRM_Related_Object__c
            ];
            String participantName;
            String participantRole;
            Id participantUserId;

            // Sjekk type thread
            if (thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER') {
                // Bruk Account
                participantName = request.Account__r.Name;
                participantRole = 'Tolkebruker';
                User user = [SELECT Id FROM User WHERE AccountId = :request.Account__r.Id LIMIT 1];
                participantUserId = user != null ? user.Id : null;
            } else if (thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER') {
                // Bruk Orderer
                participantName = request.Orderer__r.Name;
                participantRole = 'Bestiller';
                User user = [SELECT Id FROM User WHERE AccountId = :request.Orderer__r.Id LIMIT 1];
                participantUserId = user != null ? user.Id : null;
            }

            // Legg til participant hvis navn og userId finnes
            if (participantName != null && participantUserId != null) {
                participantList.add(new Participant(participantName, participantRole, participantUserId));
            }
        }
        if (
            thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
            thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' ||
            thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER'
        ) {
            participantList.add(new Participant('Formidler'));
        }
        if (thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR') {
            participantList.add(new Participant('Ressurskontor'));
        }
        return participantList;
    }
    public static String formatName(String name) {
        if (String.isBlank(name)) {
            return name;
        }
        List<String> words = name.toLowerCase().split(' ');
        List<String> capitalizedWords = new List<String>();

        for (String word : words) {
            if (word.length() > 0) {
                String capitalized = word.substring(0, 1).toUpperCase() + word.substring(1);
                capitalizedWords.add(capitalized);
            }
        }
        return String.join(capitalizedWords, ' ');
    }
}
