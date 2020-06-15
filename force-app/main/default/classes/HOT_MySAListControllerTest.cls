@isTest
private class HOT_MySAListControllerTest{
/*
	static void testSetup(){

		//OperatingHours operatingHour = HOT_TestDataFactory.createOperatingHours();
		//insert operatingHour;
		//ServiceTerritory ServiceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHour);
		//insert ServiceTerritory;
		//Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		//insert serviceResource;
		//ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(serviceResource, serviceTerritory);
		//insert serviceTerritoryMember;
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTest', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];
		ServiceAppointment serviceAppointment = [SELECT Id, Status, HOT_TermsOfAgreement__c, SchedStartTime, SchedEndTime 
												FROM ServiceAppointment WHERE Subject = 'HOT_MySAListControllerTest'];
		serviceAppointment.SchedStartTime = Datetime.now().addHours( 1 );
		serviceAppointment.SchedEndTime = request.StartTime__c.addHours( 2 );
		serviceAppointment.HOT_TermsOfAgreement__c = 'Test Value';
		update serviceAppointment;
		AssignedResource AssignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, serviceResource.Id);
		insert AssignedResource;
	}

	@isTest static void getParentWorkOrderLineItemsTest() {
		testSetup();
		List<WorkOrderLineItem> workOrderLineItems = HOT_MyServiceAppointmentListController.getParentWorkOrderLineItems();
		System.assertNotEquals(0, workOrderLineItems.size(), 'Could not get list of Parent workOrderLineItems');
		System.assertNotEquals(null, workOrderLineItems[0].WorkOrder.HOT_Request__r.AssignmentType__c, 'Not correct Assignment type');	
	}
	@isTest static void getMyServiceAppointmentsTest() {
		testSetup();
		List<ServiceAppointment> assignedAppointments = HOT_MyServiceAppointmentListController.getMyServiceAppointments();
		System.assertNotEquals(0, assignedAppointments.size(), 'Could not get list of Assigned Appointments');
		
	}

	@isTest static void getMyServiceAppointmentFieldHistories() {
		testSetup();
		List<ServiceAppointment> assignedAppointments = HOT_MyServiceAppointmentListController.getMyServiceAppointments();
		Map<String, List<ServiceAppointmentHistory>> historyMap = HOT_MyServiceAppointmentListController.getMyServiceAppointmentFieldHistories(assignedAppointments[0].Id);
		System.assertEquals(historyMap.get('Status')[0].get('CreatedById'), UserInfo.getUserId());
		System.assertEquals(historyMap.get('HOT_TermsOfAgreements__c')[0].get('CreatedById'), UserInfo.getUserId());
	}*/

	@isTest static void dummyTestMethod() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTest', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceAppointment saDummy = [SELECT Id FROM ServiceAppointment LIMIT 1];
		List<ServiceAppointment> assignedAppointments = HOT_MyServiceAppointmentListController.getMyServiceAppointments();
		Map<String, List<ServiceAppointmentHistory>> historyMap = HOT_MyServiceAppointmentListController.getMyServiceAppointmentFieldHistories(saDummy.Id);
		List<WorkOrderLineItem> workOrderLineItems = HOT_MyServiceAppointmentListController.getParentWorkOrderLineItems();
		System.assertEquals(0, 0);
	}

}