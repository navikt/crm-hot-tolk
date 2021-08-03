@isTest
private class HOT_SkillControllerTest {
    @isTest
    static void getAllSkillsListTest() {
        List<Skill> skills = HOT_SkillController.getAllSkillsList();
        System.assertEquals(8, skills.size(), 'Could not fetch allSkillsList');
    }
}
