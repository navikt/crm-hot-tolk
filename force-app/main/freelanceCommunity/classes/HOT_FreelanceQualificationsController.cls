public without sharing class HOT_FreelanceQualificationsController {
    @AuraEnabled(cacheable=true)
    public static List <ServiceResourceSkill> getServiceResourceSkill() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceResource = [
            SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId
        ];
       List <ServiceResourceSkill> freelanceServiceResourceSkill = [
            SELECT
                EffectiveStartDate,
                SkillId,
                EffectiveEndDate,
                ServiceResourceId, 
                SkillNumber,
                SkillLevel,
                Id    
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :freelanceResource.Id
           
        ];
        return freelanceServiceResourceSkill;
    }
}
