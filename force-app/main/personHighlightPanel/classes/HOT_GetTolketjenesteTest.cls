@isTest
public without sharing class HOT_GetTolketjenesteTest {
    @TestSetup
    static void makeData() {
        Person__c p = (Person__c) HOT_TestDataFactory.createPerson();
        p.INT_ActorId__c = '100003000120';
        p.INT_IsNavEmployee__c = true;
        p.INT_MunicipalityNumber__c = '1573';
        p.INT_RegionNumber__c = '15';
        insert p;
    }

    @IsTest
    static void QueueNamePerson() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE INT_ActorId__c = '100003000120'];

        Test.startTest();
        String result = HOT_GetTolketjeneste.getTolketjeneste(p.id, 'Person__c');
        Test.stopTest();

        System.assertEquals(null, result, 'null'); //Always returns null in scratch because of missing queue
    }

    @IsTest
    static void QueueNameAccount() {
        id accId = [SELECT Id FROM Account WHERE CRM_Person__r.INT_ActorId__c = '100003000120' LIMIT 1].id;

        Test.startTest();
        String result = HOT_GetTolketjeneste.getTolketjeneste(accId, 'Account');
        Test.stopTest();

        System.assertEquals(null, result, 'null'); //Always returns null in scratch because of missing queue
    }
}
