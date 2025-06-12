/*
This Class has several commented classes and setup. This is because the code works in this scratch org, 
and not in the scratch-org made during Pull Request code coverage testing. The one created during Code Coverage
testing does not include skills and profiles, which are needed in order to test this code properly.
*/
@IsTest
private class HOT_FreelanceQualificationsCtlTest {
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        /*Skill skill = [SELECT Id FROM Skill WHERE DeveloperName = 'Skrivetolking' LIMIT 1];

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            s
        );
        
        insert serviceResourceSkill;*/
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

    /*@IsTest
    static void setResourceSkillTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user3 = HOT_TestDataFactory.createUser('user3', profile);
        insert user3;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(User3.Id);
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        Test.startTest();
        ServiceResourceSkill setFreelanceSkill = HOT_FreelanceQualificationsController.setResourceSkill(
            serviceResource,
            skill
        );
        Test.stopTest();

        System.assertEquals(
            serviceResource.Id,
            setFreelanceSkill.ServiceResourceId,
            'Could not get correct serviceResourceId from setResourceSkill'
        );
    }*/

    @IsTest
    static void getAllSkillsListTest() {
        Test.startTest();
        List<Skill> skills = HOT_FreelanceQualificationsController.getAllSkillsList();
        Test.stopTest();
        //System.assertEquals(7, skills.size(), 'Could not fetch allSkillsList');
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

        //Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        ServiceResource serviceResource = [SELECT id FROM ServiceResource LIMIT 1];

        Test.startTest();
        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getUserServiceResourceSkills();
        Test.stopTest();
        //System.assertEquals(freelanceSkills[0].EffectiveStartDate, Date.today());
    }

    /*@IsTest
    static void setServiceResourceSkillsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        ServiceResource serviceResource = [SELECT id FROM ServiceResource LIMIT 1];

        Test.startTest();
        ServiceResourceSkill srSkill = HOT_FreelanceQualificationsController.setResourceSkill(serviceResource, skill);
        Test.stopTest();
        System.assertEquals(srSkill.SkillId, skill.Id);
    }*/

    /*@IsTest
    static void editServiceResourceSkillsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        ServiceResource serviceResource = [SELECT id FROM ServiceResource LIMIT 1];
        serviceResource.RelatedRecordId = UserInfo.getUserId();
        update serviceResource;

        ServiceResourceSkill srs = [SELECT Id FROM ServiceResourceSkill LIMIT 1];
        srs.EffectiveEndDate = Datetime.now();
        update srs;

        List<Skill> newSkills = new List<Skill>();
        newSkills.add(skill);
        Test.startTest();
        HOT_FreelanceQualificationsController.editServiceResourceSkill(newSkills);
        Test.stopTest();

        ServiceResourceSkill srsT = [SELECT Id, EffectiveEndDate FROM ServiceResourceSkill LIMIT 1];
        System.assertEquals(null, srsT.EffectiveEndDate, 'EffectiveEndDate should be null if skill already exists');
    }*/
}
