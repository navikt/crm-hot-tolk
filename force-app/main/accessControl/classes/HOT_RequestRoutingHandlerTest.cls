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

	@IsTest
	private static void testRequestAccountFields(){
		Person__c person = HOT_TestDataFactory.createPerson( );
		person.Name = '12015678999';
		insert person;
		Account personAccount = HOT_TestDataFactory.createAccount(true);
		personAccount.INT_PersonIdent__c = '12015678999';
		personAccount.CRM_Person__c = person.Id;
		insert personAccount;
		Account businessAccount = HOT_TestDataFactory.createAccount(false);
		businessAccount.INT_OrganizationNumber__c = '987654321';
		insert businessAccount;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c personRequest = HOT_TestDataFactory.createRequest('Person Test', workType);
		personRequest.UserPersonNumber__c = '12015678999';
		HOT_Request__c businessRequest = HOT_TestDataFactory.createRequest('Business Test', workType);
		businessRequest.OrganizationNumber__c = '987654321';

		Test.startTest();
		insert personRequest;
		insert businessRequest;
		Test.stopTest();

		personRequest = [SELECT Id, Account__c FROM HOT_Request__c WHERE Subject__c = 'Person Test'];
		businessRequest = [SELECT Id, Company__c FROM HOT_Request__c WHERE Subject__c = 'Person Test'];

		System.assertEquals(null, personRequest.Account__c, 'Could not set Account__c field');
		System.assertEquals(null, businessRequest.Company__c, 'Could not set Company__c field');
	}
}