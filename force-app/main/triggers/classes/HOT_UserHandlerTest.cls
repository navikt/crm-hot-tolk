@isTest
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

    @isTest
    static void createAnsattTolk() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
        if (profiles.size() > 0) {
            Profile profileId = profiles[0];
            User user = HOT_TestDataFactory.createUser('Testing', profileId);

            Test.startTest();
            insert user;
            Test.stopTest();

            List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
            System.assertEquals(1, serviceResources.size());
        }
    }

    //Tests if a user that was changed to HOT Ansatt Tolk has a Service Resource created.
    @isTest
    static void changedToAnsattTolk() {
        List<Profile> profileTolkFormidler = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Formidler'];
        Id oldProfileId;

        //System.assert(ProfileTolkFormidler.size() >= 1, 'Expected to have a profile');
        if (profileTolkFormidler.size() > 0) {
            Profile profileId = profileTolkFormidler[0];
    
            UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'HOT' Limit 1];
            User runningUser = [SELECT Id, UserRoleId FROM User WHERE Id=:UserInfo.getUserId() Limit 1];
            runningUser.UserRoleId = userRole.Id;
            update runningUser;
            
            System.runAs(runningUser){
                Contact contact = new Contact(FirstName='Test', LastName='Testesen');
                insert contact;
                
                Account personAccount = HOT_TestDataFactory.createAccount(true);
                insert personAccount;
                
                User user = HOT_TestDataFactory.createUser('Testing', profileId);
                
                Test.startTest();
                insert user;
                
                System.assertEquals(profileId.Id, user.ProfileId, 'Expected Ids to be the same.');
                oldProfileId = user.ProfileId;
            }
    
            User user = [SELECT Id, ProfileId FROM User WHERE ProfileId = :oldProfileId];
    
            System.assert(user.ProfileId == oldProfileId);
    
            Profile profileTolkAnsatt = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
            HOT_TestDataFactory.changeUserProfile(user, profileTolkAnsatt);
            System.assert(!(user.ProfileId == oldProfileId));
    
            update user;
            Test.stopTest();
    
            List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
            System.assertEquals(1, serviceResources.size());
        }
    }

    @isTest
    static void createAnsattTolkWithMiddleNameIncluded() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
        if (profiles.size() > 0) {
            Profile profileId = profiles[0];
            User user = HOT_TestDataFactory.createUserWithAllNames('First', 'Middle', 'Last', profileId);
            Test.startTest();
            insert user;
            Test.stopTest();

            List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
            System.assertEquals(1, serviceResources.size());
            System.assertEquals('First Middle Last', serviceResources[0].Name, 'Name not set correctly');
        }
    }
}
