@isTest
private class HOT_FieldServiceStatusHandlerTest {
	
	@isTest
    private static void testStatusChangeWorkOrderToRequest() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder;

		workOrder.Status = 'Fullført';
		update workOrder;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Covered', request.Status__c, 'Status on the request did not update to correct value');

		workOrder.Status = 'Avbrutt';
		update workOrder;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Canceled', request.Status__c, 'Status on the request did not update to correct value');
	}
	
	@isTest
    private static void testStatusChangeWorkOrderLineItemToWorkOrder() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder);
		insert workOrderLineItem;

		workOrderLineItem.Status = 'Covered';
		update workOrderLineItem;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];

		System.assertEquals('Covered', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem.Status = 'Canceled';
		update workOrderLineItem;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];

		System.assertEquals('Canceled', workOrder.Status, 'Status on the work order did not update to correct value');
	}
	
    @isTest
    private static void testStatusChangeServiceAppointmentToWorkOrderLineItem() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder);
		insert workOrderLineItem;
		ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
		insert serviceAppointment;

		serviceAppointment.Status = 'Covered';
		update serviceAppointment;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];

		System.assertEquals('Covered', workOrderLineItem.Status, 'Status on the service appointment did not update to correct value');

		serviceAppointment.Status = 'Canceled';
		update serviceAppointment;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];

		System.assertEquals('Canceled', workOrderLineItem.Status, 'Status on the service appointment did not update to correct value');
    }
}