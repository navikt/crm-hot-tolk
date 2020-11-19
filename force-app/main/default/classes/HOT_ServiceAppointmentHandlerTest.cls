@isTest
private class HOT_ServiceAppointmentHandlerTest {
	
	@isTest
    private static void testCreateHistoricallyAssignedResources() {
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
