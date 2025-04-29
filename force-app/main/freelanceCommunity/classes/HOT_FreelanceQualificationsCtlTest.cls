@IsTest
private class HOT_FreelanceQualificationsCtlTest {
    /* @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = new skill(MasterLabel = 'HOT');

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;
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

        System.assertEquals(1, skills.size(), 'There should be 1 ServiceResourceSkill record');
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

        System.assertNotEquals(0, skills.size(), 'Skills list should not be empty');
    } */
    /*
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;
    }
    @IsTest
    static void myServiceResourceTest() {
        ServiceResource freelanceInterpreter = HOT_FreelanceQualificationsController.myServiceResource();
        System.assertEquals(
            UserInfo.getUserId(),
            freelanceInterpreter.RelatedRecordId,
            'Could not find myServiceResource from getUserId'
        );
    }
    @IsTest
    static void getServiceResourceSkillTest() {
        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkill();
        System.assertEquals(1, freelanceSkills.size(), 'Could not fetch getServiceResourceSkill');
    }
    @IsTest
    static void setResourceSkillTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user3 = HOT_TestDataFactory.createUser('user3', profile);
        insert user3;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(User3.Id);
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

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

    @IsTest
    static void createServiceResourceSkillTest() {
        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        List<Skill> selectedSkills = new List<Skill>{ skill };

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        HOT_FreelanceQualificationsController.createServiceResourceSkill(serviceResource, selectedSkills);
        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkill();

        System.assertEquals(freelanceSkills[0].EffectiveStartDate, Date.today());
        System.assertEquals(freelanceSkills[0].EffectiveEndDate, null);

        selectedSkills.clear();

        HOT_FreelanceQualificationsController.createServiceResourceSkill(serviceResource, selectedSkills);
        List<ServiceResourceSkill> freelanceSkills1 = HOT_FreelanceQualificationsController.getServiceResourceSkill();

        System.assertEquals(freelanceSkills1.size(), 0, 'Could not delete serviceResourceSkills');

        Skill skill1 = [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel = 'Tegnspråktolk' LIMIT 1];
        List<Skill> selectedSkills1 = new List<Skill>{ skill1 };

        try {
            HOT_FreelanceQualificationsController.createServiceResourceSkill(serviceResource, selectedSkills1);
        } catch (Exception e) {
            String expectedExceptionThrown = e.getMessage();
            System.assertEquals(
                'Upsert failed. First exception on row 1; first error: REQUIRED_FIELD_MISSING, Required fields are missing: [ServiceResourceId]: [ServiceResourceId]',
                expectedExceptionThrown
            );
        }
    }

    @IsTest
    static void getAllSkillsListTest() {
        List<Skill> skills = HOT_FreelanceQualificationsController.getAllSkillsList();
        System.assertEquals(8, skills.size(), 'Could not fetch allSkillsList');
    }
    */
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
        System.runAs(user1) {
            ServiceResource sr = HOT_FreelanceQualificationsController.myServiceResource();
            System.assertEquals(sr.Id, resource1.Id, 'Could not get my service resource');
        }
    }
    // @IsTest
    // static void getServiceResourceSkillsTest() {
    //     ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
    //     insert serviceResource;

    //     Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

    //     ServiceResourceSkill srSkill = HOT_TestDataFactory.createServiceResourceSkill(serviceResource, skill);
    //     insert srSkill;
    //     List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getUserServiceResourceSkills();

    //     System.assertEquals(freelanceSkills[0].EffectiveStartDate, Date.today());
    // }
    // @IsTest
    // static void setServiceResourceSkillsTest() {
    //     ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
    //     insert serviceResource;
    //     WorkType workType = HOT_TestDataFactory.createWorkType();
    //     insert workType;

    //     Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

    //     ServiceResourceSkill srSkill = HOT_FreelanceQualificationsController.setResourceSkill(serviceResource, skill);

    //     System.assertEquals(srSkill.SkillId, skill.Id);
    // }
    // @IsTest
    // static void editServiceResourceSkillsTest() {
    //     ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
    //     insert serviceResource;
    //     WorkType workType = HOT_TestDataFactory.createWorkType();
    //     insert workType;

    //     List<Skill> skills = [SELECT Id, MasterLabel FROM Skill];

    //     ServiceResourceSkill srSkill = HOT_TestDataFactory.createServiceResourceSkill(serviceResource, skills[0]);
    //     srSkill.EffectiveEndDate = Datetime.now();
    //     insert srSkill;

    //     List<Skill> newSkills = new List<Skill>();
    //     newSkills.add(skills[0]);

    //     HOT_FreelanceQualificationsController.editServiceResourceSkill(skills);
    // }
    @IsTest
    static void getAllSkillsListTest() {
        List<Skill> skills = HOT_FreelanceQualificationsController.getAllSkillsList();
        System.assertEquals(skills.size(), 7);
    }
}
