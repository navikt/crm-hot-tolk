@isTest
private class HOT_FieldServiceStatusHandlerTest {
	
	@isTest
    private static void testStatusChangeWorkOrderToRequest() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder1;
		WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder2;

		workOrder1.Status = 'Scheduled';
		update workOrder1;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Reservert', request.Status__c, 'Status on the request did not update to correct value');

		workOrder2.Status = 'Dispatched';
		update workOrder2;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Tildelt', request.Status__c, 'Status on the request did not update to correct value');

		workOrder1.Status = 'Dispatched';
		update workOrder1;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Tildelt', request.Status__c, 'Status on the request did not update to correct value');

		workOrder1.Status = 'Completed';
		update workOrder1;

		workOrder2.Status = 'Cannot Completed';
		update workOrder2;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Delvis dekket', request.Status__c, 'Status on the request did not update to correct value');

		workOrder2.Status = 'Completed';
		update workOrder2;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Dekket', request.Status__c, 'Status on the request did not update to correct value');
	}
	
	@isTest
    private static void testStatusChangeWorkOrderLineItemToWorkOrder() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder;
		WorkOrderLineItem workOrderLineItem_1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
		insert workOrderLineItem_1;
		WorkOrderLineItem workOrderLineItem_2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
		insert workOrderLineItem_2;

		// Delete extra WorkOrderLineItem created by process to get full controll
		List<WorkOrderLineItem> workOrderLineItemsToDelete = [SELECT Id FROM WorkOrderLineItem WHERE Id != :workOrderLineItem_1.Id AND Id != :workOrderLineItem_2.Id];
		delete workOrderLineItemsToDelete;

		workOrderLineItem_1.Status = 'Scheduled';
		update workOrderLineItem_1;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Scheduled', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_2.Status = 'Dispatched';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Dispatched', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_2.Status = 'Cannot Complete';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Partially Complete', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_2.Status = 'Partially Complete';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Partially Complete', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_1.Status = 'In Progress';
		update workOrderLineItem_1;
		workOrderLineItem_2.Status = 'In Progress';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('In Progress', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_1.Status = 'Completed';
		update workOrderLineItem_1;
		workOrderLineItem_2.Status = 'Completed';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Completed', workOrder.Status, 'Status on the work order did not update to correct value');
	}
	
    @isTest
    private static void testStatusChangeServiceAppointmentToWorkOrderLineItem() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
		insert workOrderLineItem;
		ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
		serviceAppointment_1.HOT_Request__c = request.Id;
		insert serviceAppointment_1;
		ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
		serviceAppointment_2.HOT_Request__c = request.Id;
		insert serviceAppointment_2;

		// Delete extra ServiceAppointments created by process to get full controll
		List<ServiceAppointment> serviceAppointmentsToDelete = [SELECT Id FROM ServiceAppointment WHERE Id != :serviceAppointment_1.Id AND Id != :serviceAppointment_2.Id];
		delete serviceAppointmentsToDelete;

		Test.startTest();

		serviceAppointment_1.Status = 'Scheduled';
		update serviceAppointment_1;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		Test.startTest();
		System.assertEquals('Scheduled', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_2.Status = 'Dispatched';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Dispatched', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Cannot Complete';
		update serviceAppointment_1;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Partially Complete', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'In Progress';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'In Progress';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('In Progress', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Completed';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Completed';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Completed', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Cannot Complete';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Cannot Complete';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Cannot Complete', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');
		Test.stopTest();
	}
	
    @isTest
    private static void testCanceledServiceAppointmentToInterestedResource(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
		insert workOrderLineItem;
		ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResource;
		ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
		serviceAppointment.HOT_Request__c = request.Id;
		insert serviceAppointment;
		HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(serviceAppointment.Id, serviceResource.Id);
		insert interestedResource;

		serviceAppointment.Status = 'Canceled';
		update serviceAppointment;

		interestedResource = [SELECT Id, Status__c, Name FROM HOT_InterestedResource__c WHERE ServiceAppointment__c=:serviceAppointment.Id];
		System.assertEquals('Canceled', interestedResource.Status__c, 'Status on Interested Resource did not update to correct value');


	}

	@isTest
    private static void testStatusChangeToCancel() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		Test.startTest();
		request.Status__c = 'Avlyst';
		update request;
		Test.stopTest();

		WorkOrder workOrder = [SELECT Status FROM WorkOrder];
		System.assertEquals('Canceled', workOrder.Status, 'Status on the work order did not update to correct value');

		WorkOrderLineItem workOrderLineItem = [SELECT Status FROM WorkOrderLineItem];
		System.assertEquals('Canceled', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		ServiceAppointment serviceAppointment = [SELECT Status FROM ServiceAppointment];
		System.assertEquals('Canceled', serviceAppointment.Status, 'Status on the service appointment did not update to correct value');
	}

	@isTest
    private static void testStatusChangeToAnnul() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		Test.startTest();
		request.Status__c = 'Annullert';
		update request;
		Test.stopTest();

		WorkOrder workOrder = [SELECT Status FROM WorkOrder];
		System.assertEquals('Annul', workOrder.Status, 'Status on the work order did not update to correct value');

		WorkOrderLineItem workOrderLineItem = [SELECT Status FROM WorkOrderLineItem];
		System.assertEquals('Annul', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		ServiceAppointment serviceAppointment = [SELECT Status FROM ServiceAppointment];
		System.assertEquals('Annul', serviceAppointment.Status, 'Status on the service appointment did not update to correct value');
	}

	@isTest
    private static void testStatusChangeAnullServiceAppointmentToRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		request.NumberOfInterpreters__c = 2;
		request.Status__c = 'Godkjent';
		update request;

		WorkOrder workOrder = [SELECT Id, Status FROM WorkOrder];
		WorkOrderLineItem workOrderLineItem = [SELECT Id, Status FROM WorkOrderLineItem];
		ServiceAppointment serviceAppointment_1 = [SELECT Id, Status FROM ServiceAppointment][0];
		ServiceAppointment serviceAppointment_2 = [SELECT Id, Status FROM ServiceAppointment][1];

		serviceAppointment_1.Status = 'Annul';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Dispatched';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Id ,Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Dispatched', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		workOrder = [SELECT Id, Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Dispatched', workOrder.Status, 'Status on the work order did not update to correct value');

		request = [SELECT Id, Status__c FROM HOT_Request__c WHERE Id = :request.Id];
		System.assertEquals('Tildelt', request.Status__c, 'Status on the request did not update to correct value');

		serviceAppointment_2.Status = 'Completed';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Id ,Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Completed', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		workOrder = [SELECT Id, Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Completed', workOrder.Status, 'Status on the work order did not update to correct value');

		request = [SELECT Id, Status__c FROM HOT_Request__c WHERE Id = :request.Id];
		System.assertEquals('Dekket', request.Status__c, 'Status on the request did not update to correct value');
	}

	@isTest
    private static void testStatusChangeWithAnullServiceAppointmentToRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		request.NumberOfInterpreters__c = 2;
		request.Status__c = 'Godkjent';
		update request;

		WorkOrder workOrder = [SELECT Id, Status FROM WorkOrder];
		WorkOrderLineItem workOrderLineItem = [SELECT Id, Status FROM WorkOrderLineItem];
		ServiceAppointment serviceAppointment_1 = [SELECT Id, Status FROM ServiceAppointment][0];
		ServiceAppointment serviceAppointment_2 = [SELECT Id, Status FROM ServiceAppointment][1];

		serviceAppointment_1.Status = 'Canceled';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Annul';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Id ,Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Canceled', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		workOrder = [SELECT Id, Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Canceled', workOrder.Status, 'Status on the work order did not update to correct value');

		request = [SELECT Id, Status__c FROM HOT_Request__c WHERE Id = :request.Id];
		System.assertEquals('Avlyst', request.Status__c, 'Status on the request did not update to correct value');
	}

	@isTest
    private static void testStatusChangeToNone() {
		WorkType workType1 = HOT_TestDataFactory.createWorkType('workTypeName1');
		insert workType1;
		WorkType workType2 = HOT_TestDataFactory.createWorkType('workTypeName2');
		insert workType2;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType1, 2, workType2, 2);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		List<ServiceAppointment> serviceAppointments = [SELECT Id, Status FROM serviceAppointment WHERE HOT_Request__c = :request.Id];

		for (ServiceAppointment serviceAppointment : serviceAppointments) {
			serviceAppointment.Status = 'Dispatched';
		}

		update serviceAppointments;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Tildelt', request.Status__c, 'Status on the request did not update to correct value');

		for (ServiceAppointment serviceAppointment : serviceAppointments) {
			serviceAppointment.Status = 'None';
		}

		update serviceAppointments;
		
		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Godkjent', request.Status__c, 'Status on the request did not update to correct value');
	}
}
