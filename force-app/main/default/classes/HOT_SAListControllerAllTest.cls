@isTest
private class HOT_SAListControllerAllTest{

	@testSetup static void setup(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Request Subject', workType);
		insert request;
		request.Status__c='Godkjent';
		update request;

		WorkType workTypeNoAccess = HOT_TestDataFactory.createWorkType('No access for you');
		insert workTypeNoAccess;
		HOT_Request__c requestNoAccess = HOT_TestDataFactory.createRequest('Request Subject', workTypeNoAccess);
		insert requestNoAccess;
		request.Status__c='Godkjent';
		update requestNoAccess;

		ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResource;
		Skill skill = HOT_TestDataFactory.createSkill(workType);
		//insert skill;
		ServiceResourceSkill serviceResourceSkill = HOT_TestDataFactory.createServiceResourceSkill(serviceResource, skill);
		//insert serviceResourceSkill;
	}

	@isTest static void testMethod1() {
		List<ServiceAppointment> serviceAppointments = HOT_AllServiceAppointmentListController.getAllServiceAppointments();
		System.debug(serviceAppointments);
		//System.assertEquals(1, serviceAppointments.size());
	}

}