// Everything that is commented out is correct testcode, but because Skills is not supported in packages, they will fail when
//merging with the develop-branch

@isTest
private class HOT_FreelanceQualificationsCtlTest {
    //     @TestSetup
    //     static void setup() {
    //         ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
    //         insert serviceResource;

    //         Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

    //         ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
    //             serviceResource,
    //             skill
    //         );
    //         insert serviceResourceSkill;
    //     }
    //     @isTest
    //     static void myServiceResourceTest() {
    //         ServiceResource freelanceInterpreter = HOT_FreelanceQualificationsController.myServiceResource();
    //         System.assertEquals(
    //             UserInfo.getUserId(),
    //             freelanceInterpreter.RelatedRecordId,
    //             'Could not find myServiceResource from getUserId'
    //         );
    //     }
    //     @isTest
    //     static void getServiceResourceSkillTest() {
    //         List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkill();
    //         System.assertEquals(1, freelanceSkills.size(), 'Could not fetch getServiceResourceSkill');
    //     }
    //     @isTest
    //     static void setResourceSkillTest() {
    //         Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
    //         User user3 = HOT_TestDataFactory.createUser('user3', profile);
    //         insert user3;
    //         ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(User3.Id);
    //         insert serviceResource;

    //         Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

    //         ServiceResourceSkill setFreelanceSkill = HOT_FreelanceQualificationsController.setResourceSkill(
    //             serviceResource,
    //             skill
    //         );
    //         System.assertEquals(
    //             serviceResource.Id,
    //             setFreelanceSkill.ServiceResourceId,
    //             'Could not get correct serviceResourceId from setResourceSkill'
    //         );
    //     }

    //     @isTest
    //     static void createServiceResourceSkillTest() {
    //         Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
    //         List<Skill> selectedSkills = new List<Skill>{ skill };

    //         ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
    //         HOT_FreelanceQualificationsController.createServiceResourceSkill(serviceResource, selectedSkills);
    //         List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkill();

    //         System.assertEquals(freelanceSkills[0].EffectiveStartDate, Date.today());
    //         System.assertEquals(freelanceSkills[0].EffectiveEndDate, null);

    //         selectedSkills.clear();

    //         HOT_FreelanceQualificationsController.createServiceResourceSkill(serviceResource, selectedSkills);
    //         List<ServiceResourceSkill> freelanceSkills1 = HOT_FreelanceQualificationsController.getServiceResourceSkill();

    //         System.assertNotEquals(
    //             freelanceSkills1[0].EffectiveEndDate,
    //             null,
    //             'AssertNotEquals -> EffectiveEndDate = null failed'
    //         );

    //         Skill skill1 = [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel = 'Tegnspråktolk' LIMIT 1];
    //         List<Skill> selectedSkills1 = new List<Skill>{ skill1 };

    //         try {
    //             HOT_FreelanceQualificationsController.createServiceResourceSkill(serviceResource, selectedSkills1);
    //         } catch (Exception e) {
    //             String expectedExceptionThrown = e.getMessage();
    //             System.assertEquals(
    //                 'Upsert failed. First exception on row 1; first error: REQUIRED_FIELD_MISSING, Required fields are missing: [ServiceResourceId]: [ServiceResourceId]',
    //                 expectedExceptionThrown
    //             );
    //         }
    //     }
}
