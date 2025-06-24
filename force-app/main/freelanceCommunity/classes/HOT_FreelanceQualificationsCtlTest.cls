@IsTest
private class HOT_FreelanceQualificationsCtlTest {
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
    }

    @IsTest
    static void testMyServiceResource() {
        Test.startTest();
        ServiceResource sr = HOT_FreelanceQualificationsController.myServiceResource();
        Test.stopTest();

        System.assertNotEquals(null, sr, 'ServiceResource should not be null');
    }

    @IsTest
    static void testGetUserServiceResourceSkills() {
        Test.startTest();
        List<ServiceResourceSkill> skills = HOT_FreelanceQualificationsController.getUserServiceResourceSkills();
        Test.stopTest();

        //System.assertEquals(1, skills.size(), 'There should be 1 ServiceResourceSkill record');
    }

    @IsTest
    static void testEditServiceResourceSkill() {
        // Fetch the created skills
        List<Skill> allSkills = [SELECT Id FROM Skill LIMIT 2];
        Set<Id> allSkillIds = new Set<Id>();
        for (Skill skill : allSkills) {
            allSkillIds.add(skill.Id);
        }

        Test.startTest();
        HOT_FreelanceQualificationsController.editServiceResourceSkill(allSkills);
        Test.stopTest();

        // Verify that ServiceResourceSkill records are updated correctly
        ServiceResource sr = HOT_FreelanceQualificationsController.myServiceResource();
        List<ServiceResourceSkill> updatedSkills = [
            SELECT Id, EffectiveEndDate, SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :sr.Id
        ];

        for (ServiceResourceSkill srs : updatedSkills) {
            if (allSkillIds.contains(srs.SkillId)) {
                System.assertEquals(null, srs.EffectiveEndDate, 'EffectiveEndDate should be null for selected skills');
            } else {
                System.assertNotEquals(
                    null,
                    srs.EffectiveEndDate,
                    'EffectiveEndDate should not be null for unselected skills'
                );
            }
        }
    }

    @IsTest
    static void testGetAllSkillsList() {
        Test.startTest();
        List<Skill> skills = HOT_FreelanceQualificationsController.getAllSkillsList();
        Test.stopTest();

        //System.assertNotEquals(0, skills.size(), 'Skills list should not be empty');
    }

    @IsTest
    static void myServiceResourceTest() {
        Test.startTest();
        ServiceResource freelanceInterpreter = HOT_FreelanceQualificationsController.myServiceResource();
        Test.stopTest();
        System.assertEquals(
            UserInfo.getUserId(),
            freelanceInterpreter.RelatedRecordId,
            'Could not find myServiceResource from getUserId'
        );
    }

    @IsTest
    static void getAllSkillsListTest() {
        Test.startTest();
        List<Skill> skills = HOT_FreelanceQualificationsController.getAllSkillsList();
        Test.stopTest();
    }

    @IsTest
    static void getmyServiceResourceTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
            emailencodingkey = 'UTF-8',
            lastname = 'Testing',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = profile.Id,
            country = 'Norway',
            IsActive = true,
            timezonesidkey = 'Europe/Paris',
            username = 'HOT_testaccount@nav.hot.no'
        );
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        Test.startTest();
        System.runAs(user1) {
            ServiceResource sr = HOT_FreelanceQualificationsController.myServiceResource();
            System.assertEquals(sr.Id, resource1.Id, 'Could not get my service resource');
        }
        Test.stopTest();
    }

    @IsTest
    static void getServiceResourceSkillsTest() {
        ServiceResource serviceResource = [SELECT id FROM ServiceResource LIMIT 1];

        Test.startTest();
        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getUserServiceResourceSkills();
        Test.stopTest();
    }
}
