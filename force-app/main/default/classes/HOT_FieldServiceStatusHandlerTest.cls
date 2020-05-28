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

		workOrder.Status = 'Planlagt';
		update workOrder;

		request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

		System.assertEquals('Reservert', request.Status__c, 'Status on the request did not update to correct value');

		workOrder.Status = 'Fullført';
		update workOrder;

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

		workOrderLineItem_1.Status = 'Planlagt';
		update workOrderLineItem_1;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Planlagt', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_2.Status = 'Sendt';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Planlagt', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_2.Status = 'Kan ikke fullføre';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Delvis fullført', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_2.Status = 'Delvis fullført';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Delvis fullført', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_1.Status = 'Pågår';
		update workOrderLineItem_1;
		workOrderLineItem_2.Status = 'Pågår';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Pågår', workOrder.Status, 'Status on the work order did not update to correct value');

		workOrderLineItem_1.Status = 'Fullført';
		update workOrderLineItem_1;
		workOrderLineItem_2.Status = 'Fullført';
		update workOrderLineItem_2;

		workOrder = [SELECT Status FROM WorkOrder WHERE Id = :workOrder.Id];
		System.assertEquals('Fullført', workOrder.Status, 'Status on the work order did not update to correct value');
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
		insert serviceAppointment_1;
		ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
		insert serviceAppointment_2;

		// Delete extra ServiceAppointments created by process to get full controll
		List<ServiceAppointment> serviceAppointmentsToDelete = [SELECT Id FROM ServiceAppointment WHERE Id != :serviceAppointment_1.Id AND Id != :serviceAppointment_2.Id];
		delete serviceAppointmentsToDelete;

		serviceAppointment_1.Status = 'Planlagt';
		update serviceAppointment_1;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Planlagt', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_2.Status = 'Sendt';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Planlagt', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Kan ikke fullføre';
		update serviceAppointment_1;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Delvis fullført', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Pågår';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Pågår';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Pågår', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Fullført';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Fullført';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Fullført', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');

		serviceAppointment_1.Status = 'Kan ikke fullføre';
		update serviceAppointment_1;
		serviceAppointment_2.Status = 'Kan ikke fullføre';
		update serviceAppointment_2;

		workOrderLineItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :workOrderLineItem.Id];
		System.assertEquals('Kan ikke fullføre', workOrderLineItem.Status, 'Status on the work order line item did not update to correct value');
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
		insert serviceAppointment;
		HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(serviceAppointment.Id, serviceResource.Id);
		insert interestedResource;

		serviceAppointment.Status = 'Avbrutt';
		update serviceAppointment;

		interestedResource = [SELECT Id, Status__c, Name FROM HOT_InterestedResource__c WHERE ServiceAppointment__c=:serviceAppointment.Id];
		System.assertEquals('Canceled', interestedResource.Status__c, 'Status on Interested Resource did not update to correct value');


	}

}