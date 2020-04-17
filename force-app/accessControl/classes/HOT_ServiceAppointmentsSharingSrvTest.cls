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
		ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment( workOrderLineItem );
		insert serviceAppointment;

		List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
		Set<Id> userIds = new Set<Id>();
		for ( ServiceResource sr:serviceResources ) {
			userIds.add( sr.RelatedRecordId );
		}
		Map<Id, Set<Id> > usersByServiceAppointment = new Map<Id, Set<Id> >();
		usersByServiceAppointment.put( serviceAppointment.Id, userIds );
		Test.startTest();
		HOT_ServiceAppointmentsSharingService.grantAccess( usersByServiceAppointment );
		Test.stopTest();

		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : serviceResources[0].RelatedRecordId AND ParentId = : serviceAppointment.Id AND RowCause = 'Manual'] );
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

		Map<Id, Set<Id> > usersByServiceAppointment = new Map<Id, Set<Id> >();
		usersByServiceAppointment.put( serviceAppointment_1.Id, userIds );
		Test.startTest();
		HOT_ServiceAppointmentsSharingService.removeAccessForSpecificUsers( usersByServiceAppointment );
		Test.stopTest();
		//one manual share should be deleted. One left
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE RowCause = 'Manual'] );
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : serviceResources[0].RelatedRecordId AND ParentId = : serviceAppointment_2.Id AND RowCause = 'Manual'] );
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
