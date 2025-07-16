@IsTest
private inherited sharing class HOT_PersonAccessBadgesControllerTest {
    @IsTest
    static void getPersonAccessBadgesNavEmployee() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'UGRADERT',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = true,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :p.Id];

        List<HOT_PersonAccessBadgesController.AccessBadge> result;

        Test.startTest();
        result = HOT_PersonAccessBadgesController.getPersonAccessBadges('CRM_Person__c', 'Account', p.CRM_Account__c);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one result');
    }

    @IsTest
    static void getPersonAccessBadgesFORTROLIG() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'FORTROLIG',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = false,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :p.Id];

        List<HOT_PersonAccessBadgesController.AccessBadge> result;

        Test.startTest();
        result = HOT_PersonAccessBadgesController.getPersonAccessBadges('CRM_Person__c', 'Account', p.CRM_Account__c);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one result');
        System.assertEquals('Skjermet adresse - fortrolig', result[0].label, 'Expected Skjermet adresse - fortrolig');
    }

    @IsTest
    static void getPersonAccessBadgesSTRENGT_FORTROLIG() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'STRENGT_FORTROLIG',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = false,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :p.Id];

        List<HOT_PersonAccessBadgesController.AccessBadge> result;

        Test.startTest();
        result = HOT_PersonAccessBadgesController.getPersonAccessBadges('CRM_Person__c', 'Account', p.CRM_Account__c);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one result');
        System.assertEquals(
            'Skjermet adresse - strengt fortrolig',
            result[0].label,
            'Expected Skjermet adresse - strengt fortrolig'
        );
    }

    @IsTest
    static void getPersonAccessBadgesSTRENGT_FORTROLIG_UTLAND() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'STRENGT_FORTROLIG_UTLAND',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = false,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :p.Id];

        List<HOT_PersonAccessBadgesController.AccessBadge> result;

        Test.startTest();
        result = HOT_PersonAccessBadgesController.getPersonAccessBadges('CRM_Person__c', 'Account', p.CRM_Account__c);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one result');
        System.assertEquals(
            'Skjermet adresse - strengt fortrolig',
            result[0].label,
            'Expected Skjermet adresse - strengt fortrolig'
        );
    }
}
