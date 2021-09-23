@isTest
private class HOT_SendSMSOnStatusChangeBatchTest {
    @TestSetup
    static void setup() {
    }

    @isTest
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

        HOT_SendSMSOnStatusChangeBatch instance = new HOT_SendSMSOnStatusChangeBatch();
        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();
    }

    @isTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 30 9 ? 2030';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_SendSMSOnStatusChangeBatch',
            cron_exp,
            new HOT_SendSMSOnStatusChangeBatch()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
