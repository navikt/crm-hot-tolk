public without sharing class HOT_InterestedResourcesListController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_InterestedResource__c> getInterestedResources() {
        Id userId = UserInfo.getUserId();
        List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];

        List<HOT_InterestedResource__c> interestedResources = [
            SELECT
                Id,
                Name,
                Comments__c,
                toLabel(Status__c),
                ServiceAppointmentStartTime__c,
                ServiceAppointmentEndTime__c,
                ServiceAppointmentAddress__c,
                ServiceAppointmentFreelanceSubject__c,
                ServiceAppointment__c,
                AppointmentNumber__c,
                NumberOfInterestedResources__c,
                ServiceAppointment__r.HOT_FreelanceSubject__c,
                WorkTypeName__c,
                ServiceAppointment__r.HOT_DeadlineDate__c,
                ServiceAppointmentCity__c,
                ServiceAppointment__r.ServiceTerritory.Name,
                ServiceAppointment__r.HOT_AssignmentType__c,
                ServiceAppointment__r.HOT_IsSerieoppdrag__c,
                ServiceAppointment__r.HOT_RequestNumber__c,
                ServiceAppointment__r.HOT_ReleaseDate__c,
                ServiceAppointment__r.HOT_ReleasedBy__c,
                ServiceAppointment__r.HOT_Request__r.OwnerName__c,
                AssignmentType__c,
                AppointmentDeadlineDate__c,
                AppointmentServiceTerritory__c,
                AppointmentServiceTerritoryDeveloperName__c,
                WorkOrderCanceledDate__c,
                HOT_TermsOfAgreement__c,
                HOT_DelPol_ToHideRecord__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceResource__c IN :serviceResource
                AND HOT_DelPol_ToHideRecord__c = FALSE
                AND Status__c != 'Wanted'
            ORDER BY ServiceAppointmentStartTime__c ASC
        ];
        return interestedResources;
    }
    @AuraEnabled(cacheable=true)
    public static Boolean checkAccessToSA(String saId) {
        Boolean hasAccess = false;
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        if (serviceResource.Id != null) {
            List<HOT_InterestedResource__c> ir = [
                SELECT Id
                FROM HOT_InterestedResource__c
                WHERE ServiceAppointment__c = :saId AND ServiceResource__c = :serviceResource.Id
            ];
            if (ir.size() > 0) {
                hasAccess = true;
            }
        }
        return hasAccess;
    }
    @AuraEnabled
    public static void retractInterest(String interestedResourceId) {
        HOT_InterestedResource__c interestedResources = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResourceId
        ];
        if (interestedResources.Status__c == 'Interested') {
            interestedResources.Status__c = 'Retracted Interest';
        }
        update interestedResources;
    }
    @AuraEnabled
    public static void retractInterests(List<String> retractionIds) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id IN :retractionIds
        ];
        for (HOT_InterestedResource__c IR : interestedResources) {
            if (IR.Status__c == 'Interested') {
                IR.Status__c = 'Retracted Interest';
            }
        }
        update interestedResources;
    }
    @AuraEnabled
    public static void resendInterest(Id interestedId) {
        HOT_InterestedResource__c interestedResource = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedId
        ];
        interestedResource.Status__c = 'Interested';
        update interestedResource;
    }

    @AuraEnabled
    public static Thread__c startAThreadAndAddComment(Id interestedResourceId, String newComment, Id userContactId) {
        HOT_InterestedResource__c ir = [
            SELECT
                Id,
                ServiceAppointment__r.Subject,
                ServiceAppointment__r.HOT_Request__r.Dispatcher__c,
                ServiceResource__r.AccountId
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResourceId
        ];
        Thread__c thread = new Thread__c();
        thread.CRM_Related_Object__c = interestedResourceId;
        thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Account__c = ir.ServiceResource__r.AccountId;
        thread.HOT_InterestedResource__c = interestedResourceId;
        thread.HOT_Title__c = ir.ServiceAppointment__r.Subject;
        thread.HOT_Dispatcher__c = ir.ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
        if (userContactId != null) {
            thread.HOT_Last_message_from__c = userContactId;
            thread.HOT_Last_message_from__c = userContactId;
            thread.HOT_Thread_read_by__c = userContactId;
            thread.CRM_Latest_Message_Datetime__c = Datetime.now();
        }
        return thread;
    }

    @AuraEnabled
    public static String getThreadDispatcherId(String interestedResourceId) {
        String Id = '';
        try {
            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c = :interestedResourceId LIMIT 1];
            if (thread.Id != null) {
                Id = thread.Id;
                return Id;
            }

            return Id;
        } catch (Exception E) {
        }
        return Id;
    }
    @AuraEnabled
    public static String getThreadDispatcherIdSA(String saId) {
        String Id = '';
        try {
            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c = :saId LIMIT 1];
            if (thread.Id != null) {
                Id = thread.Id;
                return Id;
            }

            return Id;
        } catch (Exception E) {
        }
        return Id;
    }
    @AuraEnabled
    public static HOT_InterestedResource__c getInterestedResourceDetails(String recordId) {
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
        HOT_InterestedResource__c interestedResource = [
            SELECT
                Id,
                HOT_TermsOfAgreement__c,
                AppointmentNumber__c,
                ServiceAppointmentStartTime__c,
                ServiceAppointmentEndTime__c,
                ServiceAppointmentAddress__c,
                WorkTypeName__c,
                AssignmentType__c,
                Status__c,
                ServiceAppointment__r.HOT_ReleaseDate__c,
                ServiceAppointment__r.HOT_ReleasedBy__c,
                ServiceAppointment__r.HOT_Request__r.OwnerName__c,
                NumberOfInterestedResources__c,
                AppointmentDeadlineDate__c,
                AppointmentServiceTerritory__c,
                ServiceAppointmentFreelanceSubject__c,
                WorkOrderCanceledDate__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :recordId AND ServiceResource__r.AccountId = :currentUser.AccountId
        ];
        return interestedResource;
    }
}
