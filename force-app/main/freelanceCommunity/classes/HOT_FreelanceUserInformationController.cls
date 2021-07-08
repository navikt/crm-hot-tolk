public without sharing class HOT_FreelanceUserInformationController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getServiceResource() {
        Id userId = UserInfo.getUserId();
     //  ServiceResource currentServiceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];
        ServiceResource freelanceServiceResource = [

            SELECT
            HOT_IsFreelanceInterpreter__c,
            AccountId,
            // OwnerId,
            HOT_IsAvailableForAcuteAssignments__c,
            RelatedRecordId,
            //HOT_AddressOverride__c,

            HOT_Skilled__c,
            Name
            FROM ServiceResource
            //WHERE AccountId = :userId
            WHERE HOT_IsFreelanceInterpreter__c = :true //AND recordId = :userId
        ];
        return freelanceServiceResource;

        
    }
}
