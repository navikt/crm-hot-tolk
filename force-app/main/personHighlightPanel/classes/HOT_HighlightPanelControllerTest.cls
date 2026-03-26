@isTest
private without sharing class HOT_HighlightPanelControllerTest {
    @TestSetup
    static void setup() {
        Person__c testPerson = new Person__c(
            Name = 'Test Person',
            INT_Confidential__c = 'FORTROLIG',
            INT_IsNavEmployee__c = false
        );
        insert testPerson;
    }
    @IsTest
    static void testGetPerson() {
        Person__c testPerson = [
            SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c
            FROM Person__c
            WHERE Name = 'Test Person'
            LIMIT 1
        ];

        System.Test.startTest();
        Person__c result = HOT_HighlightPanelController.getPerson(testPerson.Id);
        System.Test.stopTest();

        System.assertNotEquals(null, result, 'The returned Person__c should not be null');
        System.assertEquals(testPerson.Id, result.Id, 'The returned Id should match the inserted record');
        System.assertEquals(
            testPerson.INT_Confidential__c,
            result.INT_Confidential__c,
            'INT_Confidential__c should match'
        );
        System.assertEquals(
            testPerson.INT_IsNavEmployee__c,
            result.INT_IsNavEmployee__c,
            'INT_IsNavEmployee__c should match'
        );
    }
}
