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
        List<Profile> profiles = [SELECT Id, Name FROM Profile];
        System.debug(JSON.serializePretty(profiles));
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
        List<Profile> profileIdNavBruker = [SELECT Id FROM Profile WHERE Name = 'NAV Bruker Plus'];
         System.assert(profileIdNavBruker.size() >= 1, 'Expected to have a profile');
         System.debug(profileIdNavBruker);
            Profile profileId = profileIdNavBruker[0];

            
            
            UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'HOT' Limit 1];
            
            //User runningUser = new User(Id=UserInfo.getUserId(), UserRoleId=userRole.Id);
            User runningUser = [SELECT Id, UserRoleId FROM User WHERE Id=:UserInfo.getUserId() Limit 1];
            runningUser.UserRoleId = userRole.Id;
            update runningUser;
            
            
            //user.ContactId = contact.Id;
            //System.debug(user);
            //System.debug(userRole);
            System.runAs(runningUser){
                
                Contact contact = new Contact(FirstName='Test', LastName='Testesen');
                insert contact;
                
                Account personAccount = HOT_TestDataFactory.createAccount(true);
                insert personAccount;
                
                
                UserRole testUserRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'UUserCustomerPersonAccount' Limit 1];
                User user = HOT_TestDataFactory.createUserWithContactId(profileId, personAccount, contact);
                user.UserRoleId = testUserRole.Id;
                system.debug(user);
                
                Test.startTest();
                insert user;
                Test.stopTest();
            }

            // if(profilesAnsattTolk.size() > 0 ){
            //     HOT_TestDataFactory.changeUserProfile(user, profilesAnsattTolk[0]);   
            // }

            //List<Profiles> profilesHOTAnsattTolk = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
        

        System.assertEquals('HOT Ansatt Tolk', '-user.profile.her-', 'User profile was not "HOT Ansatt Tolk"');
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
