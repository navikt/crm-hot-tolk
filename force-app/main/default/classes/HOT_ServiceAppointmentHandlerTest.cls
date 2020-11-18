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
}