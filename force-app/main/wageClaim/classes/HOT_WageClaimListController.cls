public without sharing class HOT_WageClaimListController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_WageClaim__c> getMyWageClaims() {
        List<HOT_WageClaim__c> wageClaims = [
            SELECT
                Id,
                StartTime__c,
                EndTime__c,
                AssignmentType__c,
                ServiceAppointmentName__c,
                WorkTypeName__c,
                toLabel(Status__c),
                ServiceTerritoryName__c,
                ServiceAppointmentCity__c,
                ParentWageClaim__c,
                ServiceResource__r.AccountId,
                ServiceAppointment__r.HOT_Request__r.OwnerName__c,
                DegreeOfHearingAndVisualImpairment__c
            FROM HOT_WageClaim__c
            WHERE
                Type__c = 'Available on Wage'
                AND Status__c != 'Annul'
                AND ServiceResource__r.RelatedRecordId = :UserInfo.getUserId()
            ORDER BY StartTime__c ASC
        ];
        return wageClaims;
    }

    @AuraEnabled
    public static void retractAvailability(Id recordId) {
        HOT_WageClaim__c wageClaim = new HOT_WageClaim__c(Id = recordId);
        wageClaim.Status__c = 'Retracted Availability';
        try {
            update wageClaim;
        } catch (Exception e) {
            throw e;
        }
    }
     @AuraEnabled
    public static String getThreadId(String wageClaimeId) {
         String Id='';
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:wageClaimeId LIMIT 1];
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
    public static HOT_WageClaim__c getWageClaimDetails(String recordId) {
    User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
      HOT_WageClaim__c wageClaim= [
            SELECT  Id, ServiceAppointmentName__c, StartTime__c, EndTime__c, ServiceAppointmentCity__c, Status__c, WorkTypeName__c, DegreeOfHearingAndVisualImpairment__c,ServiceAppointment__r.HOT_Request__r.OwnerName__c,AssignmentType__c FROM HOT_WageClaim__c
            WHERE Id=:recordId AND ServiceResource__r.AccountId=:currentUser.AccountId
        ];
        return wageClaim;
    }
}
