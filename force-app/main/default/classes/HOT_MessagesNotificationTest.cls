@IsTest
private class HOT_MessagesNotificationTest {
    @TestSetup
    static void makeData() {
        User navEmployee = HOT_TestDataFactory.getUsers(1, 'System Administrator', true, true)[0];
        System.runAs(navEmployee) {
            List<Account> personAccounts = HOT_TestDataFactory.getPersonAccounts(2);
            Map<String, Account> accountByLastName = new Map<String, Account>();
            for (Account acc : personAccounts) {
                accountByLastName.put(acc.LastName, acc);
            }

            Set<Id> personAccountIds = new Set<Id>();
            List<Person__c> persons = [SELECT INT_LastName__c, CRM_Account__c FROM Person__c];

            Boolean isNotficationChannelSMS = true;
            for (Person__c person : persons) {
                person.CRM_Account__c = accountByLastName.get(person.INT_LastName__c).Id;
                person.INT_KrrMobilePhone__c = '123456789';
                person.HOT_IsReservationAgainstNotifications__c = false;
                if (isNotficationChannelSMS) {
                    person.HOT_NotificationChannel__c = 'SMS';
                } else {
                    person.HOT_NotificationChannel__c = 'Push-varsel i appen';
                }
                isNotficationChannelSMS = !isNotficationChannelSMS;
                personAccountIds.add(person.CRM_Account__c);
            }
            update persons;
            List<User> users = HOT_TestDataFactory.getEmployerCommunityUser(
                personAccountIds,
                'Customer Community Plus User',
                true
            );

            PermissionSet permSet = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'FieldServiceMobileStandardPermSet'
                LIMIT 1
            ];

            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = users[0].Id,
                PermissionSetId = permSet.Id
            );
            insert psa;
            PermissionSetAssignment psa2 = new PermissionSetAssignment(
                AssigneeId = users[1].Id,
                PermissionSetId = permSet.Id
            );
            insert psa2;

            ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(users[0].Id);
            insert serviceResource;
            ServiceResource serviceResource2 = HOT_TestDataFactory.createServiceResource(users[1].Id);
            insert serviceResource2;
        }
    }

    @IsTest
    static void NotifyUserPushTestOnNewMessageFromFormidler() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'Push-varsel i appen'
        ];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_IsEmployeeThread__c = true;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();
        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyUser(threadIds);
        test.stopTest();
    }

    @IsTest
    static void NotifyUserSMSTestOnNewMessageFromFormidler() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'SMS'
            LIMIT 1
        ];

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_IsEmployeeThread__c = true;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();
        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyUser(threadIds);
        test.stopTest();
    }

    @IsTest
    static void NotifyUserPushTestOnRessurskontor() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'Push-varsel i appen'
            LIMIT 1
        ];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-RESSURSKONTOR');
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_IsEmployeeThread__c = false;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }
        test.startTest();
        HOT_MessagesNotification.NotifyUser(threadIds);
        test.stopTest();
    }

    @IsTest
    static void NotifyUserSMSTestOnRessurskontor() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'SMS'
        ];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-RESSURSKONTOR');
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyUser(threadIds);
        test.stopTest();
    }

    @IsTest
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyUser(threadIds);
        test.stopTest();
    }

    @IsTest
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.notifyUser(threadIds);
        test.stopTest();
    }

    @IsTest
    static void NotifyDispatcherTest() {
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyDispatcher(threadIds);
        test.stopTest();
    }

    @IsTest
    static void NotifyInterpreterTest() {
        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        List<User> ulist = [SELECT id FROM User WHERE contactId != NULL LIMIT 5];
        String parti = '';
        for (user u : ulist) {
            parti = parti + u.id + ', ';
        }
        parti = parti.substring(0, parti.length() - 2);

        ServiceResource s1 = [SELECT id FROM ServiceResource WHERE RelatedRecordId = :ulist[0].Id LIMIT 1];
        s1.HOT_IsEmployedInterpreter__c = true;
        update s1;

        ServiceResource s2 = [SELECT id FROM ServiceResource WHERE RelatedRecordId = :ulist[1].Id LIMIT 1];
        s2.HOT_IsFreelanceInterpreter__c = true;
        update s2;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();
        thread.HOT_ParticipantIds__c = parti;
        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyInterpreter(threadIds);
        test.stopTest();
    }

    @IsTest
    static void NotifyInterpreterTestSMS() {
        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        List<User> ulist = [SELECT id FROM User WHERE contactId != NULL LIMIT 5];
        String parti = '';
        for (user u : ulist) {
            parti = parti + u.id + ', ';
        }
        parti = parti.substring(0, parti.length() - 2);

        ServiceResource s1 = [SELECT id FROM ServiceResource WHERE RelatedRecordId = :ulist[1].Id LIMIT 1];
        s1.HOT_IsFreelanceInterpreter__c = true;
        s1.HOT_NotificationChannel__c = 'SMS';
        update s1;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();
        thread.HOT_ParticipantIds__c = parti;
        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');
        insert message;

        List<Id> threadIds = new List<Id>();
        List<Thread__c> threads = [SELECT Id FROM Thread__c];
        for (Thread__c t : threads) {
            threadIds.add(t.Id);
        }

        test.startTest();
        HOT_MessagesNotification.NotifyInterpreter(threadIds);
        test.stopTest();
    }
}
