public without sharing class HOT_ThreadParticipants {
    public class Participant {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String role;
        @AuraEnabled
        public Id userId;
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
        List<Participant> participantList = new List<Participant>();
        List<ServiceAppointment> assignedServiceAppointments = [
            SELECT
                Id,
                HOT_ServiceResource__r.RelatedRecordId,
                HOT_ServiceResource__r.Name,
                HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE
                HOT_WorkOrderLineItem__r.WorkOrderId = :thread.CRM_Related_Object__c
                AND HOT_ServiceResource__r.Name != NULL
        ];
        if (assignedServiceAppointments.size() > 0) {
            for (ServiceAppointment serviceAppointment : assignedServiceAppointments) {
                Participant participant = new Participant();
                participant.name = formatName(serviceAppointment.HOT_ServiceResource__r.Name);
                participant.role = 'Tolk';
                participant.userId = serviceAppointment.HOT_ServiceResource__r.RelatedRecordId;
                participantList.add(participant);
            }
        }
        return participantList;
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
                Participant participant = new Participant();
                participant.name = formatName(workOrder.Account.Name);
                participant.role = 'Tolkebruker';
                participant.userId = user.Id;
                participantList.add(participant);
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
                Participant participant = new Participant();
                participant.name = formatName(serviceAppointment.HOT_ServiceResource__r.Name);
                participant.role = 'Tolk';
                participant.userId = serviceAppointment.HOT_ServiceResource__r.RelatedRecordId;
                participantList.add(participant);
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
                Participant participant = new Participant();
                participant.name = formatName(interestedReource.ServiceResource__r.Name);
                participant.role = 'Tolk';
                participant.userId = interestedReource.ServiceResource__r.RelatedRecordId;
                participantList.add(participant);
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
                Participant participant = new Participant();
                participant.name = formatName(wageClaim.ServiceResource__r.Name);
                participant.role = 'Tolk';
                participant.userId = wageClaim.ServiceResource__r.RelatedRecordId;
                participantList.add(participant);
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
                Participant participant = new Participant();
                participant.name = formatName(participantName);
                participant.role = participantRole;
                participant.userId = participantUserId;
                participantList.add(participant);
            }
        }
        if (
            thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
            thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' ||
            thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER'
        ) {
            Participant participant = new Participant();
            participant.name = 'Formidler';
            participant.role = null;
            participantList.add(participant);
        }
        if (thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR') {
            Participant participant = new Participant();
            participant.name = 'Ressurskontor';
            participant.role = null;
            participantList.add(participant);
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
