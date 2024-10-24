@IsTest
private class HOT_UserHandlerTest {
    @testSetup
    static void setup() {
        Profile communityProfile = [
            SELECT Name
            FROM Profile
            WHERE
                Name = 'Personbruker Login'
                OR Name = 'Trial Customer Portal User'
                OR Name = 'Customer Community User'
                OR Name = 'Customer Community Plus User'
            LIMIT 1
        ];
        DefaultCommunityProfile__c defaultCommunityProfile = new DefaultCommunityProfile__c(
            DefaultProfile__c = communityProfile.Name,
            DefaultPermissionSet__c = 'CRM_ManageAsyncRequests',
            DefaultCommunityPlusProfile__c = 'Trial Customer Portal User',
            DefaultCommunityPlusPermissionSetGroup__c = 'Test'
        );
        insert defaultCommunityProfile;
    }

    @IsTest
    static void createAnsattTolk() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
        if (profiles.size() > 0) {
            Profile profileId = profiles[0];
            User user = HOT_TestDataFactory.createUser('Testing', profileId);

            Test.startTest();
            insert user;
            Test.stopTest();

            List<ServiceResource> serviceResources = [SELECT Id, Name, RelatedRecordId FROM ServiceResource];
            System.debug(serviceResources);
            System.assertEquals(1, serviceResources.size());
        }
    }

    //Tests if a user that was changed to HOT Ansatt Tolk has a Service Resource created.
    @IsTest
    static void changedToAnsattTolk() {
        List<Profile> profileTolkFormidler = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Formidler'];
        Id oldProfileId;

        if (profileTolkFormidler.size() > 0) {
            Profile profileId = profileTolkFormidler[0];
            User user = HOT_TestDataFactory.createUser('Testing', profileId);
            insert user;

            oldProfileId = user.ProfileId;
            System.assert(user.ProfileId == oldProfileId);

            Test.startTest();
            Profile profileTolkAnsatt = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
            HOT_TestDataFactory.changeUserProfile(user, profileTolkAnsatt);
            System.assert(!(user.ProfileId == oldProfileId));
            update user;

            Test.stopTest();
            List<ServiceResource> serviceResources = [SELECT Id, Name, RelatedRecordId FROM ServiceResource];
            System.assertEquals(1, serviceResources.size(), serviceResources);
        }
    }

    @IsTest
    static void createAnsattTolkWithMiddleNameIncluded() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
        if (profiles.size() > 0) {
            Profile profileId = profiles[0];
            User user = HOT_TestDataFactory.createUserWithAllNames('First', 'Middle', 'Last', profileId);
            Test.startTest();
            insert user;
            Test.stopTest();

            List<ServiceResource> serviceResources = [SELECT Id, Name FROM ServiceResource];
            System.assertEquals(1, serviceResources.size());
            System.assertEquals('First Middle Last', serviceResources[0].Name, 'Name not set correctly');
        }
    }
}
