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
		request.Status__c = 'Avlyst';
		update request;

		List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder];
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Status FROM WorkOrderLineItem];
		List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment];
		
		for (WorkOrder workOrder : workOrders) {
			System.assertEquals('Canceled', workOrder.Status, 'Work Order Satus was not changed to correct status');
		}
		for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
			System.assertEquals('Canceled', workOrderLineItem.Status, 'Work Order Satus was not changed to correct status');
		}
		for (ServiceAppointment serviceAppointment : serviceAppointments) {
			System.assertEquals('Canceled', serviceAppointment.Status, 'Work Order Satus was not changed to correct status');
		}
	}

	@isTest
	private static void testSetServiceTerritoryBasedOnOwner(){

		Person__c personTromso = HOT_TestDataFactory.createPerson();
		personTromso.INT_FirstName__c = 'Tromso';
		personTromso.INT_LastName__c = 'User';
		personTromso.INT_RegionNumber__c = '54';
		insert personTromso;
/*		
		Person__c personNordland = HOT_TestDataFactory.createPerson();
		personNordland.INT_FirstName__c = 'Nordland';
		personNordland.INT_LastName__c = 'User';
		personNordland.INT_RegionNumber__c = '18';
		insert personNordland;
*/
		Account accountTromso = [SELECT Id FROM Account WHERE FirstName = :personTromso.INT_FirstName__c LIMIT 1];
		//Account accountNordland = [SELECT Id FROM Account WHERE Name = :personNordland.INT_FirstName__c LIMIT 1];


		OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
		insert operatingHours;
		ServiceTerritory tromso = HOT_TestDataFactory.createServiceTerritory(operatingHours);
		tromso.HOT_DeveloperName__c = 'Tromso';
		tromso.Name = 'Tromso';
		insert tromso;
		ServiceTerritory Nordland = HOT_TestDataFactory.createServiceTerritory(operatingHours);
		Nordland.HOT_DeveloperName__c = 'Nordland';
		Nordland.Name = 'Nordland';
		insert Nordland;
		
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		request.Account__c = accountTromso.Id;
		insert request;

		request = [SELECT OwnerId, ServiceTerritory__r.Id FROM HOT_Request__c WHERE Id = :request.Id LIMIT 1];
		System.assertEquals(tromso.Id, request.ServiceTerritory__r.Id, 'ServiceTerritory was not properly set on creation');

		Group nordlandQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'queue_4718'];
		request.OwnerId = nordlandQueue.Id;
		update request;
		request = [SELECT ServiceTerritory__r.Id FROM HOT_Request__c WHERE Id = :request.Id LIMIT 1];
		System.assertEquals(Nordland.Id, request.ServiceTerritory__r.Id, 'ServiceTerritory was not properly set on update');
		
	}




	/*
	@isTest
	private static void testdeleteRelatedFiles(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		ContentVersion contentVersion = new ContentVersion(
		Title = 'Penguins',
		PathOnClient = 'Penguins.jpg',
		VersionData = Blob.valueOf('Test Content'),
		IsMajorVersion = true
		);
		insert contentVersion;    
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
		System.debug(documents.size());

		//create ContentDocumentLink  record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = request.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		insert cdl;

		List<ContentDocumentLink> files = [Select Id, ContentDocumentId From ContentDocumentLink where LinkedEntityId=:request.id];
		System.debug(files.size());
		System.assertEquals(1, files.size(), 'Was not able to add files');

		request.Status__c = 'Avlyst';
		update request;
		
		files = [Select Id, ContentDocumentId From ContentDocumentLink where LinkedEntityId=:request.id];
		System.assertEquals(0, files.size(), 'Was not able to delete files');

	}
	*/
	
}