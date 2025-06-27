@IsTest
private class HOT_UserInformationControllerTest {
    @testSetup
    static void setup() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        insert admin;
    }

    @IsTest
    static void getPersonPhoneEmailAndStatus() {
        Test.startTest();
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
        User admin = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        person.INT_KrrIntegrationStatus__c = 'Queued';
        insert person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
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
            person = HOT_UserInformationController.getPersonPhoneEmailAndStatus();
            System.assertEquals(
                'getpersontest@nav.no',
                person.INT_KrrEmail__c,
                'Expected email to be "getpersontest@nav.no"'
            );
            System.assertEquals(
                'Queued',
                person.INT_KrrIntegrationStatus__c,
                'Expected KrrIntegrationStatus to be "Queued"'
            );
        }
    }
    @IsTest
    static void getPersonTest() {
        Test.startTest();
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
        User admin = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
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
    @IsTest
    static void getAccountId() {
        Test.startTest();
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
        User admin = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
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
            User user2 = HOT_UserInformationController.getAccountId();
            System.assertEquals(account.Id, user2.AccountId);
        }

    }

    @IsTest
    static void updateKrrTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Test.startTest();
        HOT_UserInformationController.updateKrrStatus(person);
        Test.stopTest();
    }

    @IsTest
    static void getNotificationPickListValuesTest() {
        String s = 'SMS';

        Test.startTest();
        List<Map<String, String>> lm = HOT_UserInformationController.getNotificationPickListValues(s);
        Test.stopTest();
    }

    @IsTest
    static void changeUserNotificationSettingTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        String pId = person.id;
        String notval = 'SMS';
        Boolean reserved = true;

        Test.startTest();
        Boolean a = HOT_UserInformationController.changeUserNotificationSetting(pId, notval, reserved);
        Test.stopTest();
    }
}
