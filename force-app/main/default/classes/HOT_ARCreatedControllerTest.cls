@isTest
private class HOT_ARCreatedControllerTest{

	@testSetup static void setup(){

		Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResource;
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
		Hot_interestedresource__c interestedResource = new Hot_interestedresource__c (
			ServiceAppointment__c = serviceAppointment.Id,
			ServiceResource__c = serviceResource.Id,
			Comments__c = 'Test Value', 
			Status__c ='Interested'
		);
		insert interestedResource;
		 
	}

	@isTest static void updateInterestedResourceStatusTest() {
		Hot_interestedresource__c interestedResource = [SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c FROM Hot_interestedresource__c];
		AssignedResource assignedResource = new AssignedResource();
		assignedResource.ServiceAppointmentId = interestedResource.ServiceAppointment__c; 
		assignedResource.ServiceResourceId = interestedResource.ServiceResource__c;
		insert assignedResource;

		List<AssignedResource> assignedResourceList = new List<AssignedResource>{assignedResource};

		HOT_AssignedResourcesCreatedController.updateInterestedResourceStatus(assignedResourceList);
		Hot_interestedresource__c interestedResourceUpdated = [SELECT Id, Status__c FROM Hot_interestedresource__c WHERE Id = :interestedResource.Id];
		System.assertEquals('Assigned', interestedResourceUpdated.Status__c);
	}

}