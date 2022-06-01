@isTest
public with sharing class HOT_ThreadListControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;
        
        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = acc.Id;

        Thread__c t2 = new Thread__c();
        t2.CRM_Related_Object__c = acc.Id;

        Thread__c t3 = new Thread__c();
        t3.CRM_Related_Object__c = acc.Id;

        HOT_DIALOG_TestDataFactory.createRecordList(new List<Thread__c>{ t, t2, t3 });

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        insert m;
    }
    
    @isTest
    public static void getMyThreadsTest() {
        Test.startTest();
        List<Thread__c> threadList = HOT_ThreadListController.getMyThreads();
        Test.stopTest();
        System.assertEquals(new List<Thread__c>(), threadList); // Can't get current running user in test
    }
}