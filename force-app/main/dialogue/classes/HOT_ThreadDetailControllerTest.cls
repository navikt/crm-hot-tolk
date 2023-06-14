@isTest
public without sharing class HOT_ThreadDetailControllerTest {
    @isTest
    public static void getThreadDetailsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Subject__c='TEST';
        insert request;
        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c= request.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_Request__c=request.Id;
        insert t;

        Test.startTest();
        Thread__c thread = HOT_ThreadDetailController.getThreadDetails(t.Id);
        Test.stopTest();
        System.assertEquals('TEST', thread.HOT_Subject__c);
    }
}