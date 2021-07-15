public without sharing class HOT_FreelanceContactInfoController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceServiceResource = [
            SELECT
                HOT_IsFreelanceInterpreter__c,
                AccountId,
                RelatedRecordId,
                HOT_Email__c,
                HOT_EmailOverride__c,
                HOT_MobilePhone__c,
                HOT_MobilePhoneOverride__c
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return freelanceServiceResource;
    }
}
