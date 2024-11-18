@IsTest
private class HOT_ReminderSMSBatchTest {
    @TestSetup
    static void setup() {
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
                'Personbruker Login',
                true
            );
        }
    }

    @IsTest
    static void batchableTest() {
        Account account = [
            SELECT
                Id,
                OwnerId,
                Account.CRM_Person__r.INT_KrrMobilePhone__c,
                Account.CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE Account.CRM_Person__r.HOT_NotificationChannel__c = 'SMS'
            LIMIT 1
        ];
        Account account2 = [
            SELECT
                Id,
                OwnerId,
                Account.CRM_Person__r.INT_KrrMobilePhone__c,
                Account.CRM_Person__r.HOT_NotificationChannel__c
            FROM Account
            WHERE Account.CRM_Person__r.HOT_NotificationChannel__c = 'Push-varsel i appen'
            LIMIT 1
        ];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.StartTime__c = request.StartTime__c.addDays(1);
        request.EndTime__c = request.EndTime__c.addDays(1);
        request.IsReminderSMS__c = true;
        request.IsNotNotifyAccount__c = false;
        request.Account__C = account.Id;
        insert request;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        request2.StartTime__c = request2.StartTime__c.addDays(1);
        request2.EndTime__c = request2.EndTime__c.addDays(1);
        request2.IsReminderSMS__c = true;
        request2.IsNotNotifyAccount__c = false;
        request2.Account__C = account2.Id;
        insert request2;

        // To create child records
        List<HOT_Request__c> requests = [SELECT Id, Status__c FROM HOT_Request__c];
        for (HOT_Request__c r : requests) {
            r.Status__c = 'Godkjent';
        }
        update requests;

        List<WorkOrder> workOrders = [SELECT Id, Status FROM WorkOrder];
        for (Workorder w : workOrders) {
            w.Status = 'Dispatched';
        }
        update workOrders;

        HOT_ReminderSMSBatch instance = new HOT_ReminderSMSBatch();
        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2099';
        Test.startTest();
        String jobId = System.schedule('HOT_ReminderSMSBatch', cron_exp, new HOT_ReminderSMSBatch());
        Test.stopTest();
        System.assert(jobId != null);
    }
}
