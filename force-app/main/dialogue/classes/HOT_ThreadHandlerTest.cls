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
    @isTest
    static void setThreadNameBasedOnRequestTest() {
        HOT_Request__c request = [SELECT Id, OwnerId, Subject__c FROM HOT_Request__c];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.HOT_Request__c = request.Id;

        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals(request.Subject__c, thread.Name, 'Could not set thread Name based on request');
    }

    @isTest
    static void setThreadLookupOnRequestTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.HOT_Request__c = request.Id;

        Test.startTest();
        insert thread;
        Test.stopTest();

        request = [SELECT Id, Thread__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(thread.Id, request.Thread__c, 'Could not set thread lookup on request');
    }
}
