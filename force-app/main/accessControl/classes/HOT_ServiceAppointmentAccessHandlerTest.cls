@IsTest
private class HOT_ServiceAppointmentAccessHandlerTest {
	@TestSetup
	static void makeData() {
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( 'user', profile );
		insert user;
		ServiceResource resource = HOT_TestDataFactory.createServiceResource( user.Id );
		insert resource;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType );
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder( request, workType );
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem( workOrder, workType );
		insert workOrderLineItem;
		ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment;
	}

	@IsTest
	private static void testServiceResourceLoseAccessToSaWhenStatusIsChangedToCompleted() {
		ServiceAppointment serviceAppointment = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
		Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
		Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource( serviceAppointment.Id, serviceResourceId );
		insert assignedResource;

		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId AND ParentId = : serviceAppointment.Id AND RowCause = 'Manual'] );

		Test.startTest();
		serviceAppointment = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
		serviceAppointment.Status = 'Avbrutt';
		update serviceAppointment;
		Test.stopTest();
		System.assertEquals( 0, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId AND ParentId = : serviceAppointment.Id AND RowCause = 'Manual'] );
	}
}
