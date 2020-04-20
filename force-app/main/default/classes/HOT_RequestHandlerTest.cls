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

	/*
	@isTest
	private static void testdeleteRelatedFiles(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		Attachment attach=new Attachment(Name='Unit Test Attachment');
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=request.id;
		insert attach;
		
		List<ContentDocumentLink> files = [Select Id, ContentDocumentId From ContentDocumentLink where LinkedEntityId=:request.id];
		System.assertEquals(1, files.size(), 'Was not able to add files');

		request.Status__c = 'Avlyst';
		update request;
		
		files = [Select Id, ContentDocumentId From ContentDocumentLink where LinkedEntityId=:request.id];
		System.assertEquals(0, files.size(), 'Was not able to delete files');

	}
	*/
}