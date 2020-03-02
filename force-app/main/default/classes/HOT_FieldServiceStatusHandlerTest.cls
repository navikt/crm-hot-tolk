@isTest
private class HOT_FieldServiceStatusHandlerTest {
	
	@isTest
    private static void testStatusChangeWorkOrderToRequest() {
		HOT_Request__c request = HOT_TestDataFactory.createRequest();
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request);
		insert workOrder;

		Test.startTest();
		workOrder.Status = 'In Progress';
		update workOrder;
		Test.stopTest();

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals(workOrder.Status, request.Status__c, 'Status on the request did not update to correct value');
	}
	
	@isTest
    private static void testStatusChangeWorkOrderLineItemToWorkOrder() {
        //test noe
	}
	
    @isTest
    private static void testStatusChangeServiceAppointmentToWorkOrderLineItem() {
        //test noe
    }
}