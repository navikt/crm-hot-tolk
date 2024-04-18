@IsTest
private class HOT_NotifyUserOnOrderServiceBatchTest {
    @TestSetup
    static void setup() {
    }

    @IsTest
    static void batchableTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.StartTime__c = request.StartTime__c.addDays(3);
        request.EndTime__c = request.EndTime__c.addDays(3);
        insert request;

        // To create child records
        request.Status__c = 'Godkjent';
        update request;
        WorkOrder workOrder = [SELECT Id, Status, StartDate, EndDate FROM WorkOrder];
        workOrder.Status = 'Dispatched';
        update workOrder;
        workOrder.StartDate = workOrder.StartDate.addDays(-3);
        workOrder.EndDate = workOrder.EndDate.addDays(-3);
        //update workOrder;
        HOT_NotifyUserOnOrderServiceBatch instance = new HOT_NotifyUserOnOrderServiceBatch();
        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
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
