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
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c');
        System.assertEquals(
            'Push-varsel i appen',
            notifications[0].HOT_NotificationChannel__c,
            'Varslingskanalen skal være Push'
        );
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
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c');
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

        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c');
        System.assertEquals(
            'Push-varsel i appen',
            notifications[0].HOT_NotificationChannel__c,
            'Varslingskanalen skal være Push'
        );
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
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c');
    }

    @IsTest
    static void NotifyUserSMSTest() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'SMS'
        ];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet to HOT_Notification__c');
        System.assertEquals('SMS', notifications[0].HOT_NotificationChannel__c, 'Varslingskanalen skal være SMS');
    }

    @IsTest
    static void NotifyUserPushTest() {
        Account account = [
            SELECT Id, PersonContactId, CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE CRM_Person__r.HOT_NotificationChannel__c = 'Push-varsel i appen'
        ];

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c = 'HOT_BESTILLER-FORMIDLER';
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c');
        System.assertEquals(
            'Push-varsel i appen',
            notifications[0].HOT_NotificationChannel__c,
            'Varslingskanalen skal være Push'
        );
    }

    @IsTest
    static void NotifyDispatcherTest() {
        // Henter en bruker som skal motta varsel
        User dispatcherUser = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Customer Community Plus User' AND IsActive = TRUE
            LIMIT 1
        ];

        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = dispatcherUser.Id;

        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding fra en bruker';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');

        test.startTest();
        insert message;
        test.stopTest();

        // Ingen HOT_Notification__c å sjekke her, men koden er dekket og brukeren er aktiv.
    }

    @IsTest
    static void NotifyInterpreterParticipantTest() {
        ServiceResource serviceResource = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        serviceResource.HOT_IsEmployedInterpreter__c = true;
        update serviceResource;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread.HOT_ParticipantIds__c = serviceResource.RelatedRecordId;
        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c for tolken');
        System.assertEquals(
            'Push-varsel i appen',
            notifications[0].HOT_NotificationChannel__c,
            'Varslingskanalen skal være Push'
        );
    }

    @IsTest
    static void NotifyInterpreterServiceResourceTest() {
        ServiceResource serviceResource = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        update serviceResource;

        Thread__c thread = HOT_TestDataFactory.createThread();
        insert thread;

        thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.HOT_ServiceResource__c = serviceResource.Id;
        update thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = ', Formidler';

        test.startTest();
        insert message;
        test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_NotificationChannel__c, HOT_ServiceResource__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :thread.Id
        ];
        System.assertEquals(1, notifications.size(), 'Det skal være opprettet én HOT_Notification__c for tolken');
        System.assertEquals(
            serviceResource.Id,
            notifications[0].HOT_ServiceResource__c,
            'Varslet skal være koblet til riktig ServiceResource'
        );
    }
}
