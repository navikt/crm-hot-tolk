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

		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
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

	@isTest private static void testCreateHistoricallyAssignedResources() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;

		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceAppointment serviceAppointment = [SELECT Id, Status FROM ServiceAppointment];

		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( 'TEST', profile );
		insert user;

		ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
		insert resource;
		
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id);
		
		Test.startTest();
		insert assignedResource;
		Test.stopTest();

		List<HOT_HistoricallyAssignedResource__c> harList = [SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c FROM HOT_HistoricallyAssignedResource__c];
		System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
		System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
		System.assertEquals(serviceAppointment.Id, harList[0].ServiceAppointment__c, 'HAR ble ikke knyttet til korrekt oppdrag');
	}
}
