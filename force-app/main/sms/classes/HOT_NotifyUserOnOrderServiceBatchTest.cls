@IsTest
private class HOT_NotifyUserOnOrderServiceBatchTest {
    @IsTest
    static void batchableTestSMS() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Person__c p = HOT_TestDataFactory.createPerson();
        p.INT_KrrMobilePhone__c = '12345678';
        p.HOT_NotificationChannel__c = 'SMS';
        p.HOT_IsReservationAgainstNotifications__c = false;
        insert p;

        ID acc = [SELECT CRM_Account__c FROM Person__c WHERE id = :p.id].CRM_Account__c;

        HOT_Request__c request = new HOT_Request__c();
        request.Account__c = acc;
        request.IsNotNotifyAccount__c = false;
        request.IsNotifyUserOnOrder__c = true;
        insert request;

        request.Status__c = 'Godkjent';
        request.StartTime__c = system.today().addDays(2);
        request.EndTime__c = system.today().addDays(3);
        request.InterpretationMethod__c = workType.id;
        request.NumberOfInterpreters__c = 1;
        request.AssignmentType__c = 'Private';
        update request;

        HOT_NotifyUserOnOrderServiceBatch instance = new HOT_NotifyUserOnOrderServiceBatch();

        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();
    }

    @IsTest
    static void batchableTestPush() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Person__c p = HOT_TestDataFactory.createPerson();
        p.HOT_NotificationChannel__c = 'Push-varsel i appen';
        p.HOT_IsReservationAgainstNotifications__c = false;
        insert p;

        ID acc = [SELECT CRM_Account__c FROM Person__c WHERE id = :p.id].CRM_Account__c;

        HOT_Request__c request = new HOT_Request__c();
        request.Account__c = acc;
        request.IsNotNotifyAccount__c = false;
        request.IsNotifyUserOnOrder__c = true;
        insert request;

        request.Status__c = 'Godkjent';
        request.StartTime__c = system.today().addDays(2);
        request.EndTime__c = system.today().addDays(3);
        request.InterpretationMethod__c = workType.id;
        request.NumberOfInterpreters__c = 1;
        request.AssignmentType__c = 'Private';
        update request;

        HOT_NotifyUserOnOrderServiceBatch instance = new HOT_NotifyUserOnOrderServiceBatch();

        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2099';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_NotifyUserOnOrderServiceBatch',
            cron_exp,
            new HOT_NotifyUserOnOrderServiceBatch()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
