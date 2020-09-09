@isTest
private class HOT_AssignedResourceHandlerTest{

	@testSetup static void setup(){

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
		User user = HOT_TestDataFactory.createUser('User2', profile);
		insert user;
		ServiceResource serviceResourceAdmin = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResourceAdmin;
		ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
		insert serviceResource;

	}

	@isTest static void createUpdateDeleteAssignedResourceTest() {
		// code_block	
		ServiceAppointment serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment LIMIT 1];
		ServiceResource testResource = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId != :UserInfo.getUserId()];
		ServiceResource adminResource = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

		//Testing onAfterInsert()
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, adminResource.Id);
		insert assignedResource;
		serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment LIMIT 1];
		System.assertEquals(adminResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Could not set HOT_ServiceResource__c onAfterInsert');
		System.assertEquals(adminResource.RelatedRecordId, serviceAppointment.HOT_AssignedResourceId__c, 'Could not set HOT_AssignedResourceId__c onAfterInsert');
		
		//Testing onAfterUpdate()
		assignedResource.ServiceResourceId = testResource.Id;
		update assignedResource;
		serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment LIMIT 1];
		System.assertEquals(testResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Could not set HOT_ServiceResource__c onAfterUpdate');
		System.assertEquals(testResource.RelatedRecordId, serviceAppointment.HOT_AssignedResourceId__c, 'Could not set HOT_AssignedResourceId__c onAfterUpdate');
		
		//Testing onAfterdelete()
		delete assignedResource;
		serviceAppointment = [SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c FROM ServiceAppointment LIMIT 1];
		System.assertEquals(null, serviceAppointment.HOT_ServiceResource__c, 'Could not set HOT_ServiceResource__c onAfterdelete');
		System.assertEquals(null, serviceAppointment.HOT_AssignedResourceId__c, 'Could not set HOT_AssignedResourceId__c onAfterdelete');
	}

}
