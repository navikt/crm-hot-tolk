@IsTest
private class HOT_RequestRoutingHandlerTest {

	@TestSetup
	static void makeData() {
		TestDataFactory.getPublicGroup( 'HMS Troms og Finmark', 'group_4719' );
		TestDataFactory.getQueue( 'HMS Troms og Finmark', 'queue_4719', 'HOT_Request__c' );
	}

	@IsTest
	private static void testRequstRegion54() {

		Person__c person = HOT_TestDataFactory.createPerson( );
		person.INT_RegionNumber__c = '54';
		insert person;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType );
		request.Account__c = accountId;
		insert request;

		Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
		System.assertEquals( queueId, [SELECT OwnerId FROM HOT_Request__c].OwnerId );
	}
}
