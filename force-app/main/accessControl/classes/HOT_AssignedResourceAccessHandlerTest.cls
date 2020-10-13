@IsTest
private class HOT_AssignedResourceAccessHandlerTest {

	@TestSetup
	static void makeData() {
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
		User user1 = HOT_TestDataFactory.createUser( 'user1', profile );
		insert user1;
		ServiceResource resource1 = HOT_TestDataFactory.createServiceResource( user1.Id );
		insert resource1;
		User user2 = HOT_TestDataFactory.createUser( 'user2', profile );
		insert user2;
		ServiceResource resource2 = HOT_TestDataFactory.createServiceResource( user2.Id );
		insert resource2;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType );
		insert request;
		request.Status__c = 'Godkjent';
		update request;
	}

	@IsTest
	private static void testAssignedResourceHasAccessToServiceAppointmentAfterInsert() {

		Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
		Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
		Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource( serviceAppointmentId, serviceResourceId );
		insert assignedResource;

		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );
	}

	@IsTest
	private static void testUserLoseAccessWhenAssignedResourceIsDeleted() {
		Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
		Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
		Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource( serviceAppointmentId, serviceResourceId );
		insert assignedResource;

		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );

		Test.startTest();
		delete assignedResource;
		Test.stopTest();
		System.assertEquals( 0, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );
	}

	@IsTest
	private static void testWhenAssignedResourceIsChanged() {
		Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
		List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
		Id serviceResourceId1 = serviceResources[0].Id;
		Id userId1 = serviceResources[0].RelatedRecordId;
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource( serviceAppointmentId, serviceResourceId1 );
		insert assignedResource;

		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId1 AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );

		Id serviceResourceId2 = serviceResources[1].Id;
		Id userId2 = serviceResources[1].RelatedRecordId;
		System.assertEquals( 0, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId2 AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );
		Test.startTest();
		assignedResource.ServiceResourceId = serviceResourceId2;
		update assignedResource;
		Test.stopTest();
		System.assertEquals( 0, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId1 AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );
		System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE UserOrGroupId = : userId2 AND ParentId = : serviceAppointmentId AND RowCause = 'Manual'] );
	}
}
