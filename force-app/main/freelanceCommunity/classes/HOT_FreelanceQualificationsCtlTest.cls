@isTest
private class HOT_FreelanceQualificationsCtlTest {
    @TestSetup
    static void setup() {
        UserRole userRole = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert userRole;
        User user = new User(Id = UserInfo.getUserId(), UserRoleId = userRole.Id);
        update user;
    }
    @isTest
    static void myServiceResourceTest() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;

        ServiceResource freelanceInterpreter = HOT_FreelanceQualificationsController.myServiceResource();
        System.assertEquals(
            UserInfo.getUserId(),
            freelanceInterpreter.RelatedRecordId,
            'Could not find myServiceResource from getUserId'
        );
    }

    @isTest
    static void getUserServiceResourceSkillsTest() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;

        List<ServiceResourceSkill> serviceResourceSkills = HOT_FreelanceQualificationsController.getUserServiceResourceSkills();
        System.assertEquals(1, serviceResourceSkills.size(), 'Could not fetch getServiceResourceSkill');
    }

    @isTest
    static void getServiceResourceSkillTest() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;

        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkillMap()
            .values();
        System.assertEquals(1, freelanceSkills.size(), 'Could not fetch getServiceResourceSkill');
    }
    @isTest
    static void setResourceSkillTest() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user3 = HOT_TestDataFactory.createUser('user3', profile);
        insert user3;
        serviceResource = HOT_TestDataFactory.createServiceResource(User3.Id);
        insert serviceResource;

        skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill setFreelanceSkill = HOT_FreelanceQualificationsController.setResourceSkill(
            serviceResource,
            skill
        );
        System.assertEquals(
            serviceResource.Id,
            setFreelanceSkill.ServiceResourceId,
            'Could not get correct serviceResourceId from setResourceSkill'
        );
    }

    @isTest
    static void createServiceResourceSkillTest() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;

        skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        List<Skill> selectedSkills = new List<Skill>{ skill };

        serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        HOT_FreelanceQualificationsController.editServiceResourceSkill(selectedSkills);
        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkillMap()
            .values();

        System.assertEquals(freelanceSkills[0].EffectiveStartDate, Date.today());
        System.assertEquals(freelanceSkills[0].EffectiveEndDate, null);

        selectedSkills.clear();

        HOT_FreelanceQualificationsController.editServiceResourceSkill(selectedSkills);
        List<ServiceResourceSkill> freelanceSkills1 = HOT_FreelanceQualificationsController.getServiceResourceSkillMap()
            .values();

        System.assert(freelanceSkills1[0].EffectiveEndDate <= Datetime.now(), 'Could not delete serviceResourceSkills');

        Skill skill1 = [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel = 'Tegnspråktolk' LIMIT 1];
        List<Skill> selectedSkills1 = new List<Skill>{ skill1 };

        try {
            HOT_FreelanceQualificationsController.editServiceResourceSkill(selectedSkills1);
        } catch (Exception e) {
            String expectedExceptionThrown = e.getMessage();
            System.assertEquals(
                'Upsert failed. First exception on row 1; first error: REQUIRED_FIELD_MISSING, Required fields are missing: [ServiceResourceId]: [ServiceResourceId]',
                expectedExceptionThrown
            );
        }
    }

    @isTest
    static void getAllSkillsListTest() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;

        List<Skill> skills = HOT_FreelanceQualificationsController.getAllSkillsList();
        System.assertEquals(7, skills.size(), 'Could not fetch allSkillsList');
    }
}
