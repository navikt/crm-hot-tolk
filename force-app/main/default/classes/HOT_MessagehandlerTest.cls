@isTest
private class HOT_MessagehandlerTest {
    @TestSetup
    static void makeData() {
        String personAccountRecordTypeId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        Person__c person = new Person__c();
        person.INT_Confidential__c = 'UGRADERT';
        person.Name = '01010100001';
        person.INT_LastName__c = 'Test';
        person.INT_FirstName__c = 'User';
        insert person;
    }

    @isTest
    public static void messageHandlerTestWithoutDispatcher() {
        Account account = [SELECT Id, PersonContactId FROM Account];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageHandlerTestWithDispatcher() {
        Account account = [SELECT Id, PersonContactId FROM Account];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
}
