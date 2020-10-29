@isTest
private class HOT_RequestApprovedHandlerTest{

	@testSetup 
	static void setup(){

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
		request.NumberOfInterpreters__c = 2;
		insert request;


		
	}

	@isTest static void requestStatusApproved() {
		HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];

		List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
		List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
		
		//Checking that the FSL-records have not been created yet
		System.assertEquals(0, workOrders.size());
		System.assertEquals(0, workOrderLineItems.size());
		System.assertEquals(0, serviceAppointments.size());

		Test.startTest();
		request.Status__c = 'Godkjent';
		update request;
		Test.stopTest();

		workOrders = [SELECT Id FROM WorkOrder];
		workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
		serviceAppointments = [SELECT Id FROM ServiceAppointment];
		//Checking that the FSL-records have been created
		System.assertEquals(1, workOrders.size());
		System.assertEquals(1, workOrderLineItems.size());
		System.assertEquals(2, serviceAppointments.size());

	}

	@isTest static void workOrder_workOrderLineItem_serviceAppointment_Test() {
		WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
		HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		workOrder.HOT_NumberOfInterpreters__c = 2;
		
		Test.startTest();
		insert workOrder;
		Test.stopTest();

		List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
		List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
		System.assertEquals(1, workOrderLineItems.size());
		System.assertEquals(2, serviceAppointments.size());

	}

}
