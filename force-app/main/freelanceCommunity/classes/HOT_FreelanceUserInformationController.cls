public without sharing class HOT_FreelanceUserInformationController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceServiceResource = [
            SELECT
                HOT_IsFreelanceInterpreter__c,
                AccountId,
                HOT_IsAvailableForAcuteAssignments__c,
                RelatedRecordId,
                HOT_Skilled__c,
                Name,
                HOT_Email__c,
                HOT_EmailOverride__c,
                HOT_MobilePhone__c,
                HOT_MobilePhoneOverride__c,
                HOT_MobileDevice__c,
                HOT_PreferredRegions__c, 
                HOT_MoreInformation__c
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return freelanceServiceResource;
    }
}
