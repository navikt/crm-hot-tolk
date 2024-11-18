@IsTest
private class HOT_SMSStatusChangeServiceBatchTest {
    @TestSetup
    static void setup() {
        // Create a WorkType
        WorkType workType = HOT_TestDataFactory.createWorkType('Interpretation');

        // Create CRM_Persons
        Person__c person1 = HOT_TestDataFactory.createPerson('11111111111');
        person1.HOT_IsReservationAgainstNotifications__c = false;
        person1.HOT_NotificationChannel__c = 'SMS';
        insert person1;

        Person__c person2 = HOT_TestDataFactory.createPerson('22222222222');
        person2.HOT_IsReservationAgainstNotifications__c = false;
        person2.HOT_NotificationChannel__c = 'Push-varsel i appen';
        insert person2;

        // Create Accounts
        Account account1 = HOT_TestDataFactory.createAccount(true);
        account1.CRM_Person__c = person1.id;

        Account account2 = HOT_TestDataFactory.createAccount(true);
        account2.CRM_Person__c = person2.id;

        insert new List<Account>{ account1, account2 };

        // Create HOT_Requests
        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('Request 1', workType);
        request1.StartTime__c = request1.StartTime__c.addDays(3);
        request1.EndTime__c = request1.EndTime__c.addDays(3);
        request1.OrdererPhone__c = '12345678';
        request1.Orderer__c = account1.Id;
        request1.IsOrdererWantStatusUpdateOnSMS__c = true;
        insert request1;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Request 2', workType);
        request2.StartTime__c = request2.StartTime__c.addDays(3);
        request2.EndTime__c = request2.EndTime__c.addDays(3);
        request2.OrdererPhone__c = '12345678';
        request2.Orderer__c = account2.Id;
        request2.IsOrdererWantStatusUpdateOnSMS__c = true;
        insert request2;

        // Create WorkOrders
        WorkOrder wo1 = HOT_TestDataFactory.createWorkOrder(request1, workType);
        wo1.Status = 'Dispatched';
        wo1.HOT_SendSMSNotificationOnStatusChanged__c = true;
        insert wo1;

        WorkOrder wo2 = HOT_TestDataFactory.createWorkOrder(request2, workType);
        wo2.Status = 'Cannot Complete';
        wo2.HOT_SendSMSNotificationOnStatusChanged__c = true;
        insert wo2;

        wo1.Status = 'Dispatched';
        update wo1;

        wo2.Status = 'Cannot Complete';
        update wo2;
    }

    @IsTest
    static void batchableTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.StartTime__c = request.StartTime__c.addDays(3);
        request.EndTime__c = request.EndTime__c.addDays(3);
        request.OrdererPhone__c = '12345678';
        request.IsOrdererWantStatusUpdateOnSMS__c = true;
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        WorkOrder workOrder = [SELECT Id, Status, StartDate, EndDate FROM WorkOrder LIMIT 1];
        workOrder.Status = 'Dispatched';
        update workOrder;

        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        Test.startTest();
        Id batchId = Database.executeBatch(instance);
        Test.stopTest();
        System.assert(batchId != null);
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 30 9 ? 2030';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_SMSStatusChangeServiceBatch',
            cron_exp,
            new HOT_SMSStatusChangeServiceBatch()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }

    @isTest
    static void testExecute() {
        Test.startTest();
        HOT_SMSStatusChangeServiceBatch batch = new HOT_SMSStatusChangeServiceBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        List<HOT_Notification__c> notifications = [SELECT Id FROM HOT_Notification__c];
        System.assert(notifications.size() > 0, 'Expected notifications to be created.');
    }
}
