@IsTest
private class HOT_ServiceAppointmentsSharingSrvTest {

	@TestSetup
	static void makeData() {
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user = HOT_TestDataFactory.createUser( profile );
		insert user;
		ServiceResource resource = HOT_TestDataFactory.createServiceResource( user.Id );
		insert resource;
	}

	@IsTest
	private static void testGrantAccess() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType );
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder( request, workType );
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem( workOrder, workType );
		insert workOrderLineItem;
		ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_1;
		ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_2;

		List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];

		Map<Id, Id> serviceAppointmentsMap = new Map<Id, Id>();
		serviceAppointmentsMap.put( 'a0C2o00001WJvIHEA1', serviceAppointment_1.Id );
		serviceAppointmentsMap.put( 'a0C2o00001WJvIHEA2', serviceAppointment_2.Id );

		Map<Id, Id> usersMap = new Map<Id, Id>();
		usersMap.put( 'a0C2o00001WJvIHEA1', serviceResources[0].RelatedRecordId );
		usersMap.put( 'a0C2o00001WJvIHEA2', serviceResources[0].RelatedRecordId );
		Test.startTest();
		HOT_ServiceAppointmentsSharingService.grantAccess( serviceAppointmentsMap, usersMap );
		Test.stopTest();

		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : serviceResources[0].RelatedRecordId AND ParentId = : serviceAppointment_1.Id AND RowCause = 'Manual'] );
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : serviceResources[0].RelatedRecordId AND ParentId = : serviceAppointment_2.Id AND RowCause = 'Manual'] );
	}

	@IsTest
	private static void testRemoveAccessForSpecificUsers() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType );
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder( request, workType );
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem( workOrder, workType );
		insert workOrderLineItem;
		ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_1;
		ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_2;
		ServiceAppointment serviceAppointment_3 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_3;

		List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
		Set<Id> userIds = new Set<Id>();


		List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
		shares.add( new ServiceAppointmentShare(
						ParentId = serviceAppointment_1.Id,
						AccessLevel = 'Edit',
						RowCause = 'Manual',
						UserOrGroupId = serviceResources[0].RelatedRecordId
						) );
		shares.add( new ServiceAppointmentShare(
						ParentId = serviceAppointment_2.Id,
						AccessLevel = 'Edit',
						RowCause = 'Manual',
						UserOrGroupId = serviceResources[0].RelatedRecordId
						) );
		shares.add( new ServiceAppointmentShare(
						ParentId = serviceAppointment_3.Id,
						AccessLevel = 'Edit',
						RowCause = 'Manual',
						UserOrGroupId = serviceResources[0].RelatedRecordId
						) );
		insert shares;
		System.assertEquals( 3, [SELECT count() FROM ServiceAppointmentShare WHERE RowCause = 'Manual'] );

		Map<Id, Id> serviceAppointmentsMap = new Map<Id, Id>();
		serviceAppointmentsMap.put( 'a0C2o00001WJvIHEA1', serviceAppointment_1.Id );
		serviceAppointmentsMap.put( 'a0C2o00001WJvIHEA2', serviceAppointment_2.Id );

		Map<Id, Id> usersMap = new Map<Id, Id>();
		usersMap.put( 'a0C2o00001WJvIHEA1', serviceResources[0].RelatedRecordId );
		usersMap.put( 'a0C2o00001WJvIHEA2', serviceResources[0].RelatedRecordId );
		Test.startTest();
		HOT_ServiceAppointmentsSharingService.removeAccessForSpecificUsers( serviceAppointmentsMap, usersMap );
		Test.stopTest();
		//two manual shares should be deleted. One left
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE RowCause = 'Manual'] );
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE RowCause = 'Manual'] );
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : serviceResources[0].RelatedRecordId AND ParentId = : serviceAppointment_3.Id AND RowCause = 'Manual'] );
	}

	@IsTest
	private static void testRemoveManualAccess() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType );
		insert request;
		WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder( request, workType );
		insert workOrder;
		WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem( workOrder, workType );
		insert workOrderLineItem;
		ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_1;
		ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment_2;

		List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
		Set<Id> userIds = new Set<Id>();
		for ( ServiceResource sr:serviceResources ) {
			userIds.add( sr.RelatedRecordId );
		}

		List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
		shares.add( new ServiceAppointmentShare(
						ParentId = serviceAppointment_1.Id,
						AccessLevel = 'Edit',
						RowCause = 'Manual',
						UserOrGroupId = serviceResources[0].RelatedRecordId
						) );
		shares.add( new ServiceAppointmentShare(
						ParentId = serviceAppointment_2.Id,
						AccessLevel = 'Edit',
						RowCause = 'Manual',
						UserOrGroupId = serviceResources[0].RelatedRecordId
						) );
		insert shares;

		Set<Id> serviceAppointIds = new Set<Id> {serviceAppointment_1.Id};
		Test.startTest();
		HOT_ServiceAppointmentsSharingService.removeManualAccess( serviceAppointIds );
		Test.stopTest();
		//one manual share should be deleted. One left
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE RowCause = 'Manual'] );
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : serviceResources[0].RelatedRecordId AND ParentId = : serviceAppointment_2.Id AND RowCause = 'Manual'] );
	}
}
