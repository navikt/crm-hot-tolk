@isTest
private class HOT_RequestGodkjentFlowTest{

	@testSetup static void setup(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
		insert request;
	}

	@isTest static void testStatusGodkjent() {
		HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];
		request.Status__c = 'Godkjent';
		update request;

		List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
		List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
		
		System.assertEquals(1, workOrders.size(), 'WorkOrder was not created');
		System.assertEquals(1, workOrderLineItems.size(), 'WorkOrderLineItem was not created');
		System.assertEquals(1, serviceAppointments.size(), 'ServiceAppointment was not created');
	}

}