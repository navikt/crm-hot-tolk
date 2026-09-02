@IsTest
private without sharing class HOT_HighlightPanelControllerTest {
    @TestSetup
    static void setup() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;

        Account acc = HOT_TestDataFactory.createAccount(true);
        acc.CRM_Person__c = person.Id;
        insert acc;
    }

    // Helper method to create users with different profiles and link them to the person account if needed
    private static User buildUser(String key, String profileName, Account personAccount) {
        Profile profileTest = [SELECT Id, UserType FROM Profile WHERE Name = :profileName LIMIT 1];

        Integer randomNumber = Math.abs(Crypto.getRandomInteger());
        User user = HOT_TestDataFactory.createUser(key, profileTest);

        user.Username = 'hot' + key + '.' + randomNumber + '@nav.hot.nav.no';
        user.Email = 'test' + key + '@nav.hot.nav.no';
        user.Alias = key.left(8);
        user.CommunityNickname = key + randomNumber;

        if (profileTest.UserType != 'Standard') {
            user.ContactId = personAccount.PersonContactId;
        }

        return user;
    }

    @IsTest
    static void testGetAccountPersonDetailsHasAccess() {
        Account personAccount = [
            SELECT
                Id,
                PersonContactId,
                CRM_Person__c,
                CRM_Person__r.Name,
                CRM_Person__r.INT_FirstName__c,
                CRM_Person__r.INT_LastName__c
            FROM Account
            LIMIT 1
        ];

        User testUser = buildUser('hasAccess', 'System Administrator', personAccount);
        insert testUser;

        System.Test.startTest();
        System.runAs(testUser) {
            Account acc = HOT_HighlightPanelController.getAccountPersonDetails(personAccount.Id);
            System.assertEquals('12015678901', acc.CRM_Person__r.Name);

            System.assertNotEquals(null, acc, 'Account should be returned');
            System.assertEquals(personAccount.Id, acc.Id, 'Should return the requested account');
            System.assertNotEquals(null, acc.CRM_Person__c, 'Account should have person lookup set');
            System.assertNotEquals(null, acc.CRM_Person__r, 'Person relationship should be populated');

            System.assertEquals(personAccount.CRM_Person__c, acc.CRM_Person__r.Id, 'Returned person id should match');
            System.assertEquals('First', acc.CRM_Person__r.INT_FirstName__c);
            System.assertEquals('Last', acc.CRM_Person__r.INT_LastName__c);
        }
        System.Test.stopTest();
    }

    @IsTest
    static void testGetAccountPersonDetailsNoAccess() {
        Account personAccount = [
            SELECT
                Id,
                PersonContactId,
                CRM_Person__c,
                CRM_Person__r.Name,
                CRM_Person__r.INT_FirstName__c,
                CRM_Person__r.INT_LastName__c
            FROM Account
            LIMIT 1
        ];

        User testUser = buildUser('noAccess', 'Standard User', personAccount);
        insert testUser;

        System.Test.startTest();
        System.runAs(testUser) {
            Account returnedAcc = HOT_HighlightPanelController.getAccountPersonDetails(personAccount.Id);

            System.assertEquals(
                'Skjermet person',
                returnedAcc.CRM_Person__r.Name,
                'Person name should have been Skjermet person'
            );
        }
        System.Test.stopTest();
    }
}
