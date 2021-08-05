public without sharing class HOT_SkillController {
    @AuraEnabled(cacheable=true)
    public static List<Skill> getAllSkillsList() {
        List<Skill> allSkills = [SELECT Id, MasterLabel FROM Skill];
        return allSkills;
    }
}
