@isTest
public without sharing class HOT_ThreadHandlerTest {
    @TestSetup
    static void makeData() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
    }
    @isTest
    static void setThreadOwnerBasedOnRequestTest() {
        HOT_Request__c request = [SELECT Id, OwnerId FROM HOT_Request__c];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.HOT_Request__c = request.Id;

        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, OwnerId FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals(request.OwnerId, thread.OwnerId, 'Could not set thread owner based on request');
    }
}
