@isTest
private class HOT_UserInformationControllerTest {
    @testSetup
    static void setup() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [
            SELECT Id
            FROM UserRole
            WHERE Name = 'Default'
            LIMIT 1
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        insert admin;
    }

    @isTest
    static void getPersonPhoneEmailTest() {
        Test.startTest();
        Profile communityProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Customer Community Login User'
            LIMIT 1
        ];
        User admin = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT
                Id,
                OwnerId,
                PersonContactId,
                FirstName,
                LastName,
                PersonEmail,
                CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];
        account.OwnerId = admin.Id;
        update account;

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        Test.stopTest();

        System.runAs(user) {
            person = HOT_UserInformationController.getPersonPhoneEmail();
            System.assertEquals('getpersontest@nav.no', person.INT_KrrEmail__c);
        }
    }
    @isTest
    static void getPersonTest() {
        Test.startTest();
        Profile communityProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Customer Community Login User'
            LIMIT 1
        ];
        User admin = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT
                Id,
                OwnerId,
                PersonContactId,
                FirstName,
                LastName,
                PersonEmail,
                CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];
        account.OwnerId = admin.Id;
        update account;

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        Test.stopTest();

        System.runAs(user) {
            person = HOT_UserInformationController.getPerson();
            System.assertEquals(true, person.HOT_WorkplaceInterpreter__c);
        }
    }
}
