@IsTest(IsParallel=true)
public with sharing class HOT_SMSHandlerTest {
    @IsTest
    static void setArchiveAsOwnerTest() {
        SMS__c sms = HOT_TestDataFactory.createSms();
        insert sms;

        Group archive = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'HOT Arkiv' LIMIT 1];
        System.assertNotEquals(archive.Id, sms.OwnerId, 'The owner was "HOT Arkiv". Should be different owner.');

        Test.startTest();
        sms.HOT_DelPol_IsHideRecord__c = true;
        update sms;
        Test.stopTest();

        SMS__c updatedSms = [SELECT Id, OwnerId FROM SMS__c WHERE Id = :sms.Id LIMIT 1];
        System.assertEquals(archive.Id, updatedSms.OwnerId, 'The owner was not changed to "HOT Arkiv" as expected.');
    }

    @IsTest
    static void notifyDispatchersOnInsert() {
        SMS__c sms = HOT_TestDataFactory.createSms();
        sms.Type__c = 'Incoming SMS';
        insert sms;
    }
}
