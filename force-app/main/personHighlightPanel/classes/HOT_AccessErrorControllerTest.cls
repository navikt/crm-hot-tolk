@isTest
private without sharing class HOT_AccessErrorControllerTest {
    @TestSetup
    static void makeData() {
        Person__c p = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'FORTROLIG',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = true,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        id a = [SELECT Id FROM Account WHERE CRM_Person__r.INT_ActorId__c = '100003000120' LIMIT 1].id;

        Case c = new Case();
        c.Subject = 'test case';
        c.Status = 'New';
        c.Origin = 'Phone';
        c.AccountId = a;
        insert c;
    }

    @IsTest
    static void checkAccess() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE INT_ActorId__c = '100003000120'];

        String result;

        Test.startTest();
        result = HOT_AccessErrorController.checkAccess('CRM_Person__c', 'Account', p.CRM_Account__c);
        Test.stopTest();

        System.assertEquals(null, result, 'null');
    }

    @IsTest
    static void checkAccessErr() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c];

        String result;

        Test.startTest();
        result = HOT_AccessErrorController.checkAccess('CRM_Person__c', 'Account', p.id);
        Test.stopTest();

        System.assertEquals(null, result, 'null');
    }

    @IsTest
    static void fieldNameSplit() {
        Case c = [SELECT Id FROM Case WHERE Account.CRM_Person__r.INT_ActorId__c = '100003000120'];

        String result;

        Test.startTest();
        result = HOT_AccessErrorController.checkAccess('Account.CRM_Person__r.id', 'Case', c.id);
        Test.stopTest();

        System.assertEquals(null, result, 'null');
    }
}
