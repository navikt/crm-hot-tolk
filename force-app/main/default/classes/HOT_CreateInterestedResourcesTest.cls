@isTest
private class HOT_CreateInterestedResourcesTest{

	@testSetup static void setup(){

		Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResource;
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;
 
	}

	@isTest static void testMethod1() {List<ServiceAppointment> serviceAppointments = [SELECT Id, AppointmentNumber FROM ServiceAppointment];
		List<String> appointmentNumbers = new List<String>();
		for(ServiceAppointment sa:serviceAppointments){
			appointmentNumbers.add(sa.AppointmentNumber);
		}
		
		HOT_CreateInterestedResources.createInterestedResources(appointmentNumbers);
		
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id FROM HOT_InterestedResource__c];
		System.assertNotEquals(0, interestedResources.size());
	}

}