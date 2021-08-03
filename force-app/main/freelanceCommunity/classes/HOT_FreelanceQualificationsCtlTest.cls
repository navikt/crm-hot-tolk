@isTest
private class HOT_FreelanceQualificationsCtlTest {
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];
        // Skill skill = HOT_TestDataFactory.createSkill(getSkill.Id, getSkill.MasterLabel);
        // insert skill;

        ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(
            serviceResource,
            skill
        );
        insert serviceResourceSkill;
    }
    @isTest
    static void myServiceResourceTest() {
        ServiceResource freelanceInterpreter = HOT_FreelanceQualificationsController.myServiceResource();
        System.assertEquals(
            UserInfo.getUserId(),
            freelanceInterpreter.RelatedRecordId,
            'Could not find myServiceResource from getUserId'
        );
    }
    @isTest
    static void getServiceResourceSkillTest() {
        List<ServiceResourceSkill> freelanceSkills = HOT_FreelanceQualificationsController.getServiceResourceSkill();
        System.assertEquals(1, freelanceSkills.size(), 'Could not fetch getServiceResourceSkill');
    }
    @isTest
    static void setResourceSkillTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user3 = HOT_TestDataFactory.createUser('user3', profile);
        insert user3;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(User3.Id);
        insert serviceResource;

        Skill skill = [SELECT Id, MasterLabel FROM Skill LIMIT 1];

        // kan jeg hente ut data fra setup uten å legge det inn her?
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
}
