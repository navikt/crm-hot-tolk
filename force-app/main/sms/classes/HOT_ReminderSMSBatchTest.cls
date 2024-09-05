@IsTest
private class HOT_ReminderSMSBatchTest {
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
