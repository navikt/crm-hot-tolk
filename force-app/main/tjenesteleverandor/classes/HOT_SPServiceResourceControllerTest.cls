@IsTest
private class HOT_SPServiceResourceControllerTest {
    @TestSetup
    static void makeData() {
        List<Skill> skills = [
            SELECT Id, MasterLabel
            FROM Skill
            WHERE DeveloperName = 'Tegnspraktolk'
        ];

        if (skills.isEmpty()) {
            skills = (List<Skill>) Test.loadData(
                Skill.SObjectType,
                'TegnspraktolkSkill'
            );
        }

        System.runAs(new User(Id = UserInfo.getUserId())) {
            ServiceResource sr =
                HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
            insert sr;

            ServiceResourceSkill srs =
                HOT_TestDataFactory.createServiceResourceSkill(sr, skills[0]);
            insert srs;
        }
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
