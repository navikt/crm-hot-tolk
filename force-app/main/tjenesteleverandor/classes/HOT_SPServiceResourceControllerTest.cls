@IsTest
private class HOT_SPServiceResourceControllerTest {
    @TestSetup
    static void makeData() {
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(userInfo.getUserId());
        insert sr;

        Skill sk = [
            SELECT Id, MasterLabel
            FROM Skill
            WHERE DeveloperName = 'Tegnspraktolk'
            LIMIT 1
        ];
        ServiceResourceSkill srs = HOT_TestDataFactory.createServiceResourceSkill(sr, sk);
        insert srs;
    }

    @isTest
    static void getServiceResourceDetailsReturnsSRObject() {
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        
        ServiceResource output = HOT_SPServiceResourceController.getServiceResourceDetails(sr.Id);
        Assert.areNotEqual(null, output);
    }

    @isTest
    static void getServiceResourceSkillsReturnsSkillsList() {
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        List<ServiceResourceSkill> skills = HOT_SPServiceResourceController.getServiceResourceSkills(sr.Id);
        Assert.areNotEqual(null, skills);
    }
}
