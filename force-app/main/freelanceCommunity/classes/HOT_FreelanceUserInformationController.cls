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
                Name
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return freelanceServiceResource;
    }
}
