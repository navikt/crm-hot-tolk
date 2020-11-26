@isTest
private class HOT_AssignedResourceHandlerTest{

	@testSetup static void setup(){

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;
		
		HOT_Request__c request2 = HOT_TestDataFactory.createRequest('subject 2', workType);
		insert request2;
		request2.Status__c = 'Godkjent';
		update request2;

		OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
		insert operatingHours;
		ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
		insert serviceTerritory;

		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'];
		User user = HOT_TestDataFactory.createUser('User2', profile);
		insert user;
		ServiceResource serviceResourceAdmin = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		serviceResourceAdmin.HOT_IsFreelanceInterpreter__c = true;
		insert serviceResourceAdmin;
		ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
		serviceResource.HOT_IsFreelanceInterpreter__c = true;
		serviceResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
		insert serviceResource;


		ServiceAppointment serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
		HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(serviceAppointment.Id, serviceResource.Id);
		insert interestedResource;

	}

	@isTest static void createUpdateDeleteAssignedResourceTest() {
		// code_block	
		ServiceAppointment serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
		ServiceResource testResource = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId != :UserInfo.getUserId()];
		ServiceResource adminResource = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

		//Testing onAfterInsert()
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, adminResource.Id);
		insert assignedResource;
		serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Id = :serviceAppointment.Id LIMIT 1];
		System.assertEquals(adminResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Could not set HOT_ServiceResource__c onAfterInsert');
		System.assertEquals(adminResource.RelatedRecordId, serviceAppointment.HOT_AssignedResourceId__c, 'Could not set HOT_AssignedResourceId__c onAfterInsert');
		
		//Testing onAfterUpdate()
		assignedResource.ServiceResourceId = testResource.Id;
		update assignedResource;
		serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Id = :serviceAppointment.Id LIMIT 1];
		System.assertEquals(testResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Could not set HOT_ServiceResource__c onAfterUpdate');
		System.assertEquals(testResource.RelatedRecordId, serviceAppointment.HOT_AssignedResourceId__c, 'Could not set HOT_AssignedResourceId__c onAfterUpdate');
		
		//Testing updates on InterestedResources
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id, ServiceResource__c, Status__c FROM HOT_InterestedResource__c];
		System.assertEquals(2, interestedResources.size(), 'Could not create interested resources correctly');
		Map<Id, HOT_InterestedResource__c> irBySR = new Map<Id, HOT_InterestedResource__c>();
		for(HOT_InterestedResource__c interestedResource:interestedResources){
			irBySR.put(interestedResource.ServiceResource__c, interestedResource);
		}
		System.assertEquals('Assigned', irBySR.get(testResource.Id).Status__c, 'Could not set correct status on InterestedResources');
		System.assertEquals('Not Assigned', irBySR.get(adminResource.Id).Status__c, 'Could not set correct status on InterestedResources');


		//Testing onAfterdelete()
		Test.startTest();
		delete assignedResource;
		Test.stopTest();
		serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c, EarliestStartTime, DueDate, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id = :serviceAppointment.Id LIMIT 1];
		System.assertEquals(null, serviceAppointment.HOT_ServiceResource__c, 'Could not set HOT_ServiceResource__c onAfterdelete');
		System.assertEquals(null, serviceAppointment.HOT_AssignedResourceId__c, 'Could not set HOT_AssignedResourceId__c onAfterdelete');
		System.assertEquals(serviceAppointment.SchedStartTime, serviceAppointment.EarliestStartTime, 'Could not set EarliestStartTime onAfterdelete');
        System.assertEquals(serviceAppointment.SchedEndTime, serviceAppointment.DueDate, 'Could not set SchedEndTime onAfterdelete');


	}

	@isTest static void createInterestedResourcesTest(){
		
		ServiceAppointment serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
		ServiceResource testResource = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId != :UserInfo.getUserId()];
		testResource.HOT_IsFreelanceInterpreter__c = true;
		update testResource;
		//update adminResource;
		ServiceAppointment serviceAppointment2 = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment WHERE Subject = 'subject 2' LIMIT 1];
		

		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, testResource.Id);
		insert assignedResource;
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :serviceAppointment.Id];
		System.assertEquals(1, interestedResources.size(), 'Interested Resource was not created.');
		
		HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(serviceAppointment2.Id, testResource.Id);
		insert interestedResource;
		interestedResources = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :serviceAppointment2.Id];

		System.assertEquals(1, interestedResources.size(), 'Interested Resource should not have been created.');

		assignedResource.ServiceResourceId = testResource.Id;
		update assignedResource;
		interestedResources = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :serviceAppointment2.Id];
		System.assertEquals(1, interestedResources.size(), 'Interested Resource should not have been created.');
	}

}
