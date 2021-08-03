@isTest
private class HOT_SkillControllerTest {
    @TestSetup
    static void setup() {
        Skill getSkill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        Skill skill = HOT_TestDataFactory.createSkill(getSkill.Id, getSkill.MasterLabel);
        insert skill;
    }
    @isTest
    static void getAllSkillsListTest() {
        List<Skill> skills = HOT_SkillController.getAllSkillsList();
        System.assertEquals(1, skills.size(), 'Could not fetch allSkillsList');
    }
}
