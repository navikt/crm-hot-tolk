@isTest
private class HOT_MessagesNotificationTest {
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
        person.INT_KrrMobilePhone__c = '12345678';
        person.HOT_NotificationChannel__c = 'SMS';
        person.HOT_IsReservationAgainstNotifications__c = false;
        insert person;
    }

    @isTest
    static void NotifyUserSMSTest() {
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
        insert message;

        test.startTest();
        HOT_MessagesNotification.NotifyDispatcher(thread.Id);
        test.stopTest();
    }

    @isTest
    static void NotifyUserPushTest() {
        Person__c person = [
            SELECT HOT_NotificationChannel__c
            FROM Person__c
            WHERE HOT_NotificationChannel__c = 'SMS'
            LIMIT 1
        ];
        Person__c.HOT_NotificationChannel__c = 'Push-varsel i appen';
        update person;

        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        insert message;

        test.startTest();
        HOT_MessagesNotification.NotifyDispatcher(thread.Id);
        test.stopTest();
    }

    @isTest
    static void NotifyDispatcherTest() {
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
        insert message;

        test.startTest();
        HOT_MessagesNotification.NotifyDispatcher(thread.Id);
        test.stopTest();
    }
}
