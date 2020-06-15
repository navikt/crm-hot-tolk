@isTest
private class HOT_RequestListControllerTest{
	
	/* Kommentert ut pga en bug i Scrach Org som fører til at man ikke kan sette rolle på brukeren (ERROR: portal account owner must have a role)
	@TestSetup
	private static void testSetup() {
		Profile communityProfile = [SELECT Id FROM Profile WHERE Name='Customer Community User' LIMIT 1];
		
		Account account1 = HOT_TestDataFactory.createAccount(true);
		account1.LastName='User1';
		Account account2 = HOT_TestDataFactory.createAccount(true);
		account2.LastName='User2';
		insert account1; insert account2;
		account1 = [SELECT Id, PersonContactId, FirstName, LastName, PersonEmail FROM Account WHERE LastName =: account1.LastName];
		account2 = [SELECT Id, PersonContactId, FirstName, LastName, PersonEmail FROM Account WHERE LastName =: account2.LastName];
		
		Person__c person1 = HOT_TestDataFactory.createPerson(account1);
		Person__c person2 = HOT_TestDataFactory.createPerson(account2);
		insert person1; insert person2;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		Hot_request__c request1 = HOT_TestDataFactory.createRequest('Subject 1', workType);
		request1.Account__c=account1.Id;
		insert request1;
		Hot_request__c request2 = HOT_TestDataFactory.createRequest('Subject 2', workType);
		request2.Account__c=account2.Id;
		insert request2;
		Hot_request__c request2_2 = HOT_TestDataFactory.createRequest('Subject 2_2', workType);
		request2_2.Account__c=account2.Id;
		insert request2_2;

		User user1 = HOT_TestDataFactory.createUser(communityProfile, account1);
		user1.Alias = 'user1';
		user1.Username = 'HOT_testuser1@nav.hot.no';
		user1.CommunityNickname = 'user1';
		User user2 = HOT_TestDataFactory.createUser(communityProfile, account2);
		user2.Alias = 'user2';
		user2.Username = 'HOT_testuser2@nav.hot.no';
		user2.CommunityNickname = 'user2';
		System.debug(account1);
		System.debug(account2);
		insert user1; 
		insert user2;
	}

	@isTest
	private static void testgetRequestListForUser1(){
		User user1 = [SELECT Id FROM User WHERE Alias=:'user1'];
		
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Bruker'];
		PermissionSetAssignment perm1 = new PermissionSetAssignment(AssigneeId = user1.Id, PermissionSetId = ps.Id);
		insert perm1;
		
		System.runAs(user1){
			List<HOT_Request__c> req1 = HOT_RequestListContoller.getRequestList();
			System.assertEquals(req1.size(), 1, 'Was not able to select the request');
			System.assertEquals(req1[0].Subject__c, 'Subject 1', 'Was not able to select the correct request');
		}
	}

	@isTest
	private static void testgetRequestListForUser2(){
		User user2 = [SELECT Id FROM User WHERE Alias=:'user2'];
		
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Bruker'];
		PermissionSetAssignment perm2 = new PermissionSetAssignment(AssigneeId = user2.Id, PermissionSetId = ps.Id);
		insert perm2;
		
		System.runAs(user2){
			List<HOT_Request__c> req2 = HOT_RequestListContoller.getRequestList();
			System.assertEquals(req2.size(), 1, 'Was not able to select the request');
			System.assertEquals(req2[0].Subject__c, 'Subject 2', 'Was not able to select the correct request');
		}
	}
	
	@isTest
	private static void testgetRequestListFromAccountFromRequestId(){
		HOT_Request__c record = [SELECT Id FROM HOT_Request__c WHERE Subject__c=:'Subject 2_2'];
		List<HOT_Request__c> requests = HOT_RequestListContoller.getRequestListFromAccountFromRequestId(record.Id);
		System.assertEquals(requests.size(), 2, 'Was not able to select the request');
	}
	*/

	@isTest
	private static void getRequestListTestMethodDummy(){
		List<HOT_Request__c> req1 = HOT_RequestListContoller.getRequestList();
		//List<HOT_Request__c> req2 = HOT_RequestListContoller.getRequestListFromAccountFromRequestId();
	}

	@isTest
	private static void getRequestListFromAccountFromRequestIdDummy(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		Hot_request__c request1 = HOT_TestDataFactory.createRequest('Subject 1', workType);
		insert request1;
		HOT_Request__c req0 = [SELECT Id FROM HOT_Request__c];

		List<HOT_Request__c> req1 = HOT_RequestListContoller.getRequestListFromAccountFromRequestId(req0.Id);
	}

	
}