@isTest
private class HOT_RequestHandlerTest {


	
	@isTest
    private static void testStatusChangeOnReqestToAvlyst() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		// To create child records
		request.Status__c = 'Godkjent';
		update request;

		// To trigger the update of child records
		// The staus Avbrutt is translatet to Avlyst for the standard objects - so Avbrutt == Avlyst
		request.Status__c = 'Avlyst';
		update request;

		List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder];
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Status FROM WorkOrderLineItem];
		List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment];
		
		for (WorkOrder workOrder : workOrders) {
			System.assertEquals('Avbrutt', workOrder.Status, 'Work Order Satus was not changed to correct status');
		}
		for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
			System.assertEquals('Avbrutt', workOrderLineItem.Status, 'Work Order Satus was not changed to correct status');
		}
		for (ServiceAppointment serviceAppointment : serviceAppointments) {
			System.assertEquals('Avbrutt', serviceAppointment.Status, 'Work Order Satus was not changed to correct status');
		}
	}
}