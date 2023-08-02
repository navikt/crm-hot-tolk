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
                IsNewComment__c,
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
            WHERE ServiceResource__c IN :serviceResource AND HOT_DelPol_ToHideRecord__c = FALSE
            ORDER BY ServiceAppointmentStartTime__c ASC
        ];
        return interestedResources;
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
    public static void addComment(Id interestedResourceId, String newComment) {
        Datetime now = Datetime.now();
        String osloTimeZone = 
  now.format('yyyy-MM-dd-HH:mm:ss', 
                 'Europe/Oslo');
        if (newComment != null && newComment != '') {
            newComment =
                UserInfo.getFirstName() +
                ' ' +
                UserInfo.getLastName() +
                ', ' +
                osloTimeZone +
                ': ' +
                newComment;
            HOT_InterestedResource__c interestedResource = [
                SELECT Id, Comments__c, IsNewComment__c, IsDispatcherNewComment__c
                FROM HOT_InterestedResource__c
                WHERE Id = :interestedResourceId
            ];
            if (interestedResource.Comments__c == null) {
                interestedResource.Comments__c = newComment;
            } else {
                interestedResource.Comments__c = interestedResource.Comments__c + '\n\n' + newComment;
            }

            if (
                Test.isRunningTest()
                    ? true
                    : UserInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'NAV Samhandler'][0].Id
            ) {
                interestedResource.IsDispatcherNewComment__c = true;
            } else {
                interestedResource.IsNewComment__c = true;
            }
            update interestedResource;
        }
    }
    @AuraEnabled
     public static void startAThreadAndAddComment(Id interestedResourceId, String newComment) {
        if(newComment!=''){
            HOT_InterestedResource__c ir=[SELECT Id, ServiceAppointment__r.Subject, ServiceResource__r.AccountId FROM HOT_InterestedResource__c WHERE Id=:interestedResourceId];
            Thread__c thread = new Thread__c();
            thread.CRM_Related_Object__c = interestedResourceId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
            thread.CRM_Account__c = ir.ServiceResource__r.AccountId;
            thread.HOT_InterestedResource__c=interestedResourceId;
            thread.HOT_Title__c=ir.ServiceAppointment__r.Subject;
            HOT_DatabaseOperations.insertRecords(thread);

            //legg inn meldingen i comment
            Id userContactId=HOT_MessageHelper.getUserContactId();
            HOT_MessageHelper.createMessage(thread.Id, newComment, userContactId);

            //legg til read by
            HOT_MessageHelper.setLastMessageFrom(thread.Id, userContactId);
        }
    }
    @AuraEnabled
    public static void dispatcherReadComment(Id recordId) {
        HOT_InterestedResource__c interestedResource = [
            SELECT Id, IsDispatcherNewComment__c
            FROM HOT_InterestedResource__c
            WHERE Id = :recordId
        ];
        if (interestedResource.IsDispatcherNewComment__c) {
            interestedResource.IsDispatcherNewComment__c = false;
            update interestedResource;
        }
    }

    @InvocableVariable
    public ID recordId;
    @InvocableVariable
    public String newComment;

    @InvocableMethod
    public static void addComment(List<HOT_InterestedResourcesListController> inputVariables) {
        HOT_InterestedResourcesListController.addComment(inputVariables[0].recordId, inputVariables[0].newComment);
    }
    
    @AuraEnabled
    public static String getThreadDispatcherId(String interestedResourceId) {
         String Id='';
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:interestedResourceId LIMIT 1];
             if (thread.Id != null) {
               Id=thread.Id;
               return Id;
             }
             
            return Id;
        }catch(Exception E){

        }
        return Id;
    }
     @AuraEnabled
    public static String getThreadDispatcherIdSA(String saId) {
         String Id='';
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:saId LIMIT 1];
             if (thread.Id != null) {
               Id=thread.Id;
               return Id;
             }
             
            return Id;
        }catch(Exception E){

        }
        return Id;
    }
     @AuraEnabled
    public static HOT_InterestedResource__c getInterestedResourceDetails(String recordId) {
    User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
      HOT_InterestedResource__c interestedResource= [
            SELECT  Id, HOT_TermsOfAgreement__c, AppointmentNumber__c, ServiceAppointmentStartTime__c, ServiceAppointmentEndTime__c, ServiceAppointmentAddress__c, WorkTypeName__c, AssignmentType__c, Status__c, NumberOfInterestedResources__c, AppointmentDeadlineDate__c, AppointmentServiceTerritory__c, ServiceAppointmentFreelanceSubject__c, WorkOrderCanceledDate__c FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c=:recordId AND ServiceResource__r.AccountId=:currentUser.AccountId
        ];
        return interestedResource;
    }
}
