@IsTest
private class HOT_RequestRoutingHandlerTest {

	@TestSetup
	static void makeData() {
		TestDataFactory.getPublicGroup( 'HMS Troms og Finmark', 'group_4719' );
	}

	@IsTest
	private static void testRequstRegion54() {
		Account acc = HOT_TestDataFactory.createAccount( true );
		insert acc;
		Person__c person = HOT_TestDataFactory.createPerson( acc );
		person.INT_RegionNumber__c = '54';
		insert person;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest( 'TEST', workType, acc );
		insert request;

		Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_4719' LIMIT 1].Id;
		System.assertEquals( groupId, [SELECT OwnerId FROM HOT_Request__c].OwnerId );
	}
}
