@isTest
private class HOT_WorkOrderHandlerTest {
    @isTest
    private static void testSeriesStartAndEndDate() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        List<WorkOrder> workOrders = new List<WorkOrder>();

        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder1.StartDate = workOrder1.StartDate.addDays(1);
        workOrder1.EndDate = workOrder1.EndDate.addDays(1);
        workOrders.add(workOrder1);
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder2.StartDate = workOrder2.StartDate.addDays(2);
        workOrder2.EndDate = workOrder2.EndDate.addDays(2);
        workOrders.add(workOrder2);
        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder3.StartDate = workOrder1.StartDate.addDays(3);
        workOrder3.EndDate = workOrder1.EndDate.addDays(3);
        workOrders.add(workOrder3);

        Test.startTest();
        insert workOrders;

        request = [SELECT SeriesStartDate__c, SeriesEndDate__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(workOrder1.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder3.EndDate.date(), request.SeriesEndDate__c);

        workOrder2.StartDate = workOrder1.StartDate.addDays(5);
        workOrder2.EndDate = workOrder1.EndDate.addDays(5);
        update workOrder2;

        request = [SELECT SeriesStartDate__c, SeriesEndDate__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(workOrder1.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder2.EndDate.date(), request.SeriesEndDate__c);
    }
}
