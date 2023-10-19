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

        Person__c personPush = new Person__c();
        personPush.INT_Confidential__c = 'UGRADERT';
        personPush.Name = '01010100001';
        personPush.INT_LastName__c = 'Test';
        personPush.INT_FirstName__c = 'User';
        personPush.INT_KrrMobilePhone__c = '12345678';
        personPush.HOT_NotificationChannel__c = 'Push-varsel i appen';
        personPush.HOT_IsReservationAgainstNotifications__c = false;
        insert personPush;

        Account accountSMS = HOT_TestDataFactory.createAccount(true);
        accountSMS.CRM_Person__c = person.Id;
        Account accountPush = HOT_TestDataFactory.createAccount(true);
        accountPush.CRM_Person__c = personPush.Id;
    }

    @isTest
    static void NotifyUserSMSTest() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'SMS'
        ];
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
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'Push-varsel i appen'
        ];

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

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c thread : threads) {
            threadIds.add(thread.Id);
        }

        test.startTest();
        HOT_MessagesNotification.notifyUser(threadIds);
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

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c thread : threads) {
            threadIds.add(thread.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyDispatcher(threadIds);
        test.stopTest();
    }
}
