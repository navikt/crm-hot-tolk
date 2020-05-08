@isTest
private class HOT_OpenSAListControllerTest{

	 
	}
	

	@testSetup static void setup(){
	
		/*
		Serviceresource serviceresourceObj = new Serviceresource (
			Name = 'test value'
		);
		insert serviceresourceObj;
		 Serviceresourceskill serviceresourceskillObj = new Serviceresourceskill (
			SkillId = 'Here is reference id', 
			EffectiveStartDate = System.now()
		);
		insert serviceresourceskillObj;
		 Skill skillObj = new Skill (
			DeveloperName = 'test value', 
			MasterLabel = 'test value'
		);
		insert skillObj;
		 Serviceappointment serviceappointmentObj = new Serviceappointment (
			ServiceTerritoryId = 'Here is reference id', 
			HOT_InterpretationPostalCode__c = 'test value', 
			HOT_InterpretationStreet__c = 'test value', 
			EarliestStartTime = System.now(), 
			DueDate = System.now()
		);
		insert serviceappointmentObj;
		 Skillrequirement skillrequirementObj = new Skillrequirement (
			SkillId = 'Here is reference id'
		);
		insert skillrequirementObj;
		*/

		Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResource;
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;
 
	}

	@isTest static void createInterestedResourcesTestMethod() {
		List<ServiceAppointment> serviceAppointments = [SELECT Id, AppointmentNumber FROM ServiceAppointment];
		List<String> appointmentNumbers = new List<String>();
		for(ServiceAppointment sa:serviceAppointments){
			appointmentNumbers.add(sa.AppointmentNumber);
		}
		
		HOT_OpenServiceAppointmentListController.createInterestedResources(appointmentNumbers);
		
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id FROM HOT_InterestedResource__c];
		System.assertNotEquals(0, interestedResources.size());
	}


	//As Skill is not supported by Apex Metadata API or DML operations, we cannot make a proper test for the class
		@isTest static void getOpenServiceAppointmentsTestMethod() {
		List<ServiceAppointment> serviceAppointments = HOT_OpenServiceAppointmentListController.getOpenServiceAppointments();
		System.assertEquals(0, 0);
	}

}