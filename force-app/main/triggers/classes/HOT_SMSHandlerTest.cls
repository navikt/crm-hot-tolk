@isTest
public with sharing class HOT_SMSHandlerTest {
    @isTest
    static void setArchiveAsOwnerTest() {
        SMS__c sms = new SMS__c();
        insert sms;

        sms.HOT_IsSMSHidden__c = true;
        update sms;

        SMS__c updatedSms = [SELECT Id, OwnerId FROM SMS__c WHERE Id = :sms.Id LIMIT 1];
        Group archive = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'HOT Arkiv' LIMIT 1];

        System.assertEquals(archive.Id, updatedSms.OwnerId, 'The owner was not changed to "HOT Arkiv" as expected.');
    }
}
