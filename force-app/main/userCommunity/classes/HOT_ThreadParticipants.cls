public without sharing class HOT_ThreadParticipants {
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

    @AuraEnabled(cacheable=true)
    public static List<Participant> getParticipants(String threadId) {
        List<Participant> participantList = new List<Participant>();
        Thread__c thread = [
            SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c, HOT_IsEmployeeThread__c
            FROM Thread__c
            WHERE Id = :threadId
        ];
        participantList.addAll(getAssignedServiceResources(thread));
        participantList.addAll(getAccountParticipants(thread));

        return participantList;
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
