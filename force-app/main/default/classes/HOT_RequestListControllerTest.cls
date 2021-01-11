@isTest
private class HOT_RequestListControllerTest{

	@testSetup 
	static void setup(){
		User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		if(admin.UserRoleId == null){
			UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
			admin.UserRoleId = role.Id;
			update admin;
		}
	}

	@isTest
	private static void getRequestListTest(){
		User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		Person__c person = HOT_TestDataFactory.createPerson();
		insert person;
		Person__c person2 = HOT_TestDataFactory.createPerson();
		insert person2;

		Account account = [SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c FROM Account WHERE CRM_Person__c = :person.Id];
		Account account2 = [SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c FROM Account WHERE CRM_Person__c = :person2.Id];

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
		request.Account__c = account.Id;
		request.Orderer__c = account.Id;
		insert request;
		
		HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Subject 2', workType);
		request2.Account__c = account2.Id;
		request2.Orderer__c = account.Id;
		request2.StartTime__c = request2.StartTime__c.addDays(-8);
		insert request2;
		HOT_Request__c request3 = HOT_TestDataFactory.createRequest('Subject 3', workType);
		request3.Account__c = account2.Id;
		request3.Orderer__c = account.Id;
		request3.StartTime__c = request3.StartTime__c.addDays(-8);
		insert request3;
		request3.Status__c = 'Godkjent';
		update request3;
		
		Test.startTest();
        Profile communityProfile = [SELECT Name FROM Profile WHERE Name='Personbruker Login' OR Name='Trial Customer Portal User' LIMIT 1];
		User user = HOT_TestDataFactory.createUser(communityProfile, account);
		user.Alias = 'userTest';
		user.Username = 'HOT_testuser1@nav.hot.no';
		user.CommunityNickname = 'userTest';
		insert user; 
		Test.stopTest();

		System.runAs(user){
			List<HOT_Request__c> requests = HOT_RequestListContoller.getRequestList();
			System.assertEquals(3, requests.size(), 'Could not get my requests');
		}
		List<HOT_Request__c> requests = HOT_RequestListContoller.getRequestList();
		System.assertEquals(null, requests, 'Falsly fetched requests');

	}


	@isTest
	private static void getTimesTest(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		Hot_request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		List<Map<String, String>> times = HOT_RequestListContoller.getTimes(new List<String>{(String) request.Id});
		System.assertEquals(1, times.size(), 'Could not get times');

	}

	@isTest
	private static void getRequestListFromAccountFromRequestIdTest(){
		Person__c person = HOT_TestDataFactory.createPerson();
		insert person;
		Account account = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1];
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		Hot_request__c request1 = HOT_TestDataFactory.createRequest('My Request 1', workType);
		request1.Account__c = account.Id;
		insert request1;
		Hot_request__c request2 = HOT_TestDataFactory.createRequest('My Request 2', workType);
		request2.Account__c = account.Id;
		insert request2;
		Hot_request__c request3 = HOT_TestDataFactory.createRequest('NOT My Request', workType);
		insert request3;
		List<HOT_Request__c> requests = HOT_RequestListContoller.getRequestListFromAccountFromRequestId(request1.Id);
		List<Id> requestIds = new List<Id>();
		for(HOT_Request__c request:requests){
			requestIds.add(request.Id);
		}
		System.assertEquals(true, requestIds.contains(request1.Id), 'Could not fetch Request 1');
		System.assertEquals(true, requestIds.contains(request2.Id), 'Could not fetch Request 2');
		System.assertEquals(false, requestIds.contains(request3.Id), 'Falsly fetched Request 3');
	}

	
}