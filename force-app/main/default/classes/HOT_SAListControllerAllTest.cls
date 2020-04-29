@isTest
private class HOT_SAListControllerAllTest{

	@testSetup static void setup(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Request Subject', workType);
		insert request;
		request.Status__c='Godkjent';
		update request;
	}

	@isTest static void testMethod1() {
		List<ServiceAppointment> serviceAppointments = HOT_ServiceAppointmentListControllerAll.getAllServiceAppointments();
		System.debug(serviceAppointments);
		System.assertEquals(1, serviceAppointments.size());
	}

}