@IsTest
private class HOT_SMSStatusChangeServiceBatchTest {
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
        request.OrdererPhone__c = '12345678';
        request.IsOrdererWantStatusUpdateOnSMS__c = true;
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        WorkOrder workOrder = [SELECT Id, Status, StartDate, EndDate FROM WorkOrder];
        workOrder.Status = 'Dispatched';
        update workOrder;

        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        Test.startTest();
        Id batchId = database.executebatch(instance);
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
}
