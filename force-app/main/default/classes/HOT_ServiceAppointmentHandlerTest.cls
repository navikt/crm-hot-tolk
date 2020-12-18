@isTest
private class HOT_ServiceAppointmentHandlerTest{
	
	@testSetup static void setup(){
		OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
		insert operatingHours;
		ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
		insert serviceTerritory;
		
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( 'user', profile );
		insert user;
		ServiceResource resource = HOT_TestDataFactory.createServiceResource( user.Id );
		resource.HOT_IsFreelanceInterpreter__c = true;
		insert resource;
		ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);
		insert serviceTerritoryMember;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert WorkType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
		request.PreferredInterpreter1__c = resource.Id;
		request.NumberOfInterpreters__c = 2;
		insert request;

		request.Status__c = 'Godkjent';
		update request;
	}

	@isTest static void setStatusDefaultTest() {
		ServiceAppointment serviceAppointment = [SELECT Status FROM ServiceAppointment WHERE HOT_PreferredInterpreter__c != null];
		System.assertEquals('None', serviceAppointment.Status, 'Default status was not set on ServiceAppointment.');
	}

	@isTest static void setOwnerTest() {
		HOT_Request__c request = [SELECT OwnerId FROM HOT_Request__c];
		ServiceAppointment serviceAppointment = [SELECT OwnerId FROM ServiceAppointment WHERE HOT_PreferredInterpreter__c != null];
		System.assertEquals(request.OwnerId, serviceAppointment.OwnerId, 'Owner of ServiceAppointment was not set to owner of Request.');
	}
	@isTest static void setFieldsByPreferredInterpreterTest_onInsert() {
		ServiceResource serviceResource = [SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_ServiceTerritory__c FROM ServiceResource];
		ServiceAppointment serviceAppointment = [SELECT HOT_IsReleasedToFreelance__c, ServiceTerritoryId FROM ServiceAppointment WHERE HOT_PreferredInterpreter__c != null];
		System.assertEquals(serviceResource.HOT_ServiceTerritory__c, serviceAppointment.ServiceTerritoryId, 'ServiceTerritory on ServiceAppointment was not set to ServiceTerritory on PreferredInterpreters.');
		System.assertEquals(serviceResource.HOT_IsFreelanceInterpreter__c, serviceAppointment.HOT_IsReleasedToFreelance__c, 'IsFreelanceInterpreter on ServiceAppointment was not set to IsFreelanceInterpreter on PreferredInterpreters.');
	}
	@isTest static void setFieldsByPreferredInterpreterTest_onUpdate() {
		ServiceResource serviceResource = [SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_IsEmployedInterpreter__c, HOT_ServiceTerritory__c FROM ServiceResource];
		serviceResource.HOT_IsFreelanceInterpreter__c = false;
		serviceResource.HOT_IsEmployedInterpreter__c = true;
		//update serviceResource;

		ServiceAppointment serviceAppointment = [SELECT Id, HOT_PreferredInterpreter__c FROM ServiceAppointment WHERE HOT_PreferredInterpreter__c = null];
		serviceAppointment.HOT_PreferredInterpreter__c = serviceResource.Id;

		Test.startTest();
		update serviceAppointment;
		Test.stopTest();

		serviceResource = [SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_ServiceTerritory__c FROM ServiceResource];
		serviceAppointment = [SELECT HOT_IsReleasedToFreelance__c, ServiceTerritoryId FROM ServiceAppointment WHERE Id = :serviceAppointment.Id];
		System.assertEquals(serviceResource.HOT_ServiceTerritory__c, serviceAppointment.ServiceTerritoryId, 'ServiceTerritory on ServiceAppointment was not set to ServiceTerritory on PreferredInterpreters.');
		System.assertEquals(serviceResource.HOT_IsFreelanceInterpreter__c, serviceAppointment.HOT_IsReleasedToFreelance__c, 'IsFreelanceInterpreter on ServiceAppointment was not set to IsFreelanceInterpreter on PreferredInterpreters.');
	}
	
	@isTest static void cancelServiceAppointment() {
		ServiceAppointment sa = [SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment LIMIT 1];
		sa.HOT_CanceledByInterpreter__c = true;
		update sa;

		//Checking if SA is cancelled etc
		system.assertEquals(true, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to true');

		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'];
		User user2 = HOT_TestDataFactory.createUser('User2', profile);
		insert user2;

		ServiceResource sr = HOT_TestDataFactory.createServiceResource(user2.Id);
		insert sr;

		AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
		insert ar;

		sa = [SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment WHERE Id = :sa.Id LIMIT 1];

		//Checks if HOT_CancelledByInterpreter is no longer checked
		System.assertEquals(false, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to false');
	}

	@isTest static void changeStatusAndRemoveSR() {
		WorkType wt = HOT_TestDataFactory.createWorkType();
		HOT_Request__c req = HOT_TestDataFactory.createRequest('Test', wt);
		WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
		WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
		ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);

		sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];

		sa.Status = 'Scheduled';
		upsert sa;

		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'];
		User user2 = HOT_TestDataFactory.createUser('User2', profile);
		insert user2;

		ServiceResource sr = HOT_TestDataFactory.createServiceResource(user2.Id);
		insert sr;

		AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
		insert ar;

		sa.Status = 'Canceled';
		update sa;
	
		sa = [SELECT Id, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Id = :sa.Id LIMIT 1];
		System.assertEquals(null, sa.HOT_AssignedResourceId__c, 'Could not set AR');
	}

	@isTest private static void testCreateHistoricallyAssignedResources_addResource() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;

		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( 'TEST', profile );
		insert user;

		ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
		insert resource;
		
		Test.startTest();
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id);
		
		//Added Resource
		insert assignedResource;
		Test.stopTest();

		List<HOT_HistoricallyAssignedResource__c> harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c];
		System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
		System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
		System.assertEquals(serviceAppointment.Id, harList[0].ServiceAppointment__c, 'HAR ble ikke knyttet til korrekt oppdrag');
		
		HOT_HistoricallyAssignedResource__c prevHAR = harList[0];

	}

	@isTest private static void testCreateHistoricallyAssignedResources_statusChange() {
	
		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
		ServiceResource resource = [SELECT Id FROM ServiceResource];
		
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id);
		insert assignedResource;
		
		//Change status on ServiceAppointment
		serviceAppointment.Status = 'Dispatched';
		Test.startTest();
		update serviceAppointment;
		Test.stopTest();

		List<HOT_HistoricallyAssignedResource__c> harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c WHERE Status__c = 'Tildelt'];
		System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
		System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
		System.assertEquals(serviceAppointment.Id, harList[0].ServiceAppointment__c, 'HAR ble ikke knyttet til korrekt oppdrag');
		System.assertEquals('Tildelt', harList[0].Status__c, 'Status har ikke blitt satt korrekt på HAR');
		
	}
	@isTest private static void testCreateHistoricallyAssignedResources_resourceChange() {
	
		
		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
		ServiceResource resource = [SELECT Id FROM ServiceResource];
		
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id);
		insert assignedResource;
		

		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( 'user2', profile );
		insert user;
		ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user.Id);
		insert resource2;
		
		assignedResource = [SELECT Id, ServiceResourceId, ServiceAppointmentId FROM AssignedResource WHERE Id = :assignedResource.Id];
		assignedResource.ServiceResourceId = resource2.Id;
	 	
		Test.startTest();
		update assignedResource;
		Test.stopTest();

		//Old resource
		List<HOT_HistoricallyAssignedResource__c> harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c WHERE Status__c = 'Tolk tatt av oppdraget'];
		System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
		System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
		System.assertEquals(serviceAppointment.Id, harList[0].ServiceAppointment__c, 'HAR ble ikke knyttet til korrekt oppdrag');
		System.assertEquals('Tolk tatt av oppdraget', harList[0].Status__c, 'Status har ikke blitt satt korrekt på HAR');
		
		//New resource
		harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c WHERE ServiceResource__c = :resource2.Id];
		System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
		System.assertEquals(resource2.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
		System.assertEquals(serviceAppointment.Id, harList[0].ServiceAppointment__c, 'HAR ble ikke knyttet til korrekt oppdrag');
		
	}

	@isTest private static void testCreateHistoricallyAssignedResources_removedResource() {
	
		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
		ServiceResource resource = [SELECT Id FROM ServiceResource];
		
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id);
		insert assignedResource;
		
		//Remove assigned resource
		Test.startTest();
		delete assignedResource;
		Test.stopTest();

		List<HOT_HistoricallyAssignedResource__c> harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c WHERE Status__c = 'Tolk tatt av oppdraget'];
		System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
		System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
		System.assertEquals(serviceAppointment.Id, harList[0].ServiceAppointment__c, 'HAR ble ikke knyttet til korrekt oppdrag');
		System.assertEquals('Tolk tatt av oppdraget', harList[0].Status__c, 'Status har ikke blitt satt korrekt på HAR');
		
	}


	@isTest private static void testDoNotCreateHAR() {
		Test.startTest();
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;

		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( 'TEST', profile );
		insert user;

		ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
		insert resource;
		
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id);
		insert assignedResource;

		
		serviceAppointment.Status = 'Cancel';
		serviceAppointment.HOT_DoNotCreateHAR__c = true;
		update serviceAppointment;
		Test.stopTest();

		List<HOT_HistoricallyAssignedResource__c> harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c];
		serviceAppointment = [SELECT Id, HOT_DoNotCreateHAR__c FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

		System.assertEquals(1, harList.size());
		System.assertEquals(false, serviceAppointment.HOT_DoNotCreateHAR__c);
	}
	@isTest private static void testGetTranslatedStatus() {
		Map<String, String> correctStatuses = new Map<String, String>();
		correctStatuses.put('', '');
		correctStatuses.put('Annul', 'Annullert');
		correctStatuses.put('Canceled', 'Avlyst av bruker');
		correctStatuses.put('Cannot Complete', 'Udekket');
		correctStatuses.put('Completed', 'Dekket');
		correctStatuses.put('Dispatched', 'Tildelt');
		correctStatuses.put('In Progress', 'Pågår');
		correctStatuses.put('None', 'Åpen');
		correctStatuses.put('Released to Freelance', 'Frigitt til frilanstolker');
		correctStatuses.put('Scheduled', 'Reservert');
		for(String key:correctStatuses.keySet()){
			System.assertEquals(correctStatuses.get(key), HOT_ServiceAppointmentHandler.getTranslatedStatus(key));
		}
	}

	@isTest private static void testNotifyUsers() {
		Test.startTest();
		ServiceAppointment serviceAppointment = [SELECT Id, Status, SchedStartTime, Street FROM ServiceAppointment LIMIT 1];
		serviceAppointment.Status = 'Canceled';
		serviceAppointment.SchedStartTime = Datetime.now();
		serviceAppointment.Street = 'Street2789462894';
		update serviceAppointment;
		Test.stopTest();
	}
}
