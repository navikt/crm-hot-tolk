public with sharing class HOT_SPServiceResourceController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getServiceResourceDetails(Id recordId) {
        return [
            SELECT
                Id,
                HOT_Address__c,
                HOT_Email__c,
                HOT_MobilePhone__c,
                HOT_MobileDevice__c,
                HOT_NotificationChannel__c,
                Name,
                IsActive,
                HOT_PreferredRegions__c,
                HOT_Skilled__c,
                HOT_ServiceTerritory__r.Name,
                HOT_MoreInformation__c,
                Description
            FROM ServiceResource
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceResourceSkill> getServiceResourceSkills(Id resourceId) {
        return [
            SELECT SkillId, EffectiveEndDate, ServiceResourceId, Id, Skill.MasterLabel
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :resourceId
            WITH SECURITY_ENFORCED
        ];
    }
}