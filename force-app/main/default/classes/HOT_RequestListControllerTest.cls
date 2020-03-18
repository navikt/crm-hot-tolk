@isTest
public class HOT_RequestListControllerTest{

	@TestSetup static void testSetup() {
		Profile profileID = [SELECT Id FROM Profile WHERE Name='Customer Community User' LIMIT 1];
		String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
		
		Account account01 = new Account(RecordTypeId = recordTypeId, FirstName = 'Test', LastName = 'User1', PersonEmail = 'testuser1Email@nav.hot.no');
		Account account02 = new Account(RecordTypeId = recordTypeId, FirstName = 'Test', LastName = 'User2', PersonEmail = 'testuser2Email@nav.hot.no');
		insert account01; insert account02;
		List<Account> accounts = [SELECT Id, PersonContactId, FirstName, LastName, PersonEmail FROM Account];
		Account account1 = accounts[0];
		Account account2 = accounts[1];
		
		Person__c person1 = new Person__c(Account__c=account1.Id);
		Person__c person2 = new Person__c(Account__c=account2.Id);
		insert person1; insert person2;

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		Hot_request__c request1 = HOT_TestDataFactory.createRequest('Subject 1', workType);
		request1.Account__c=account1.Id;
		insert request1;
		Hot_request__c request2 = HOT_TestDataFactory.createRequest('Subject 2', workType);
		request2.Account__c=account2.Id;
		insert request2;


		User user1 = new User (
			Username = 'testuser1.03162020@nav.hot.no', 
			LastName = 'user1', 
			Email = 'testuser1Email@nav.hot.no', 
			Alias = 'user1', 
			CommunityNickname = 'user1', 
			TimeZoneSidKey ='Europe/Paris', 
			LocaleSidKey ='no_NO', 
			EmailEncodingKey ='UTF-8', 
			ProfileId = profileID.id, 
			LanguageLocaleKey ='no',
			ContactId=account1.PersonContactId
			//AccountId=account1.Id
		);
		
		User user2 = new User (
			Username = 'testuser2.03162020@nav.hot.no', 
			LastName = 'user2', 
			Email = 'testuser2Email@nav.hot.no', 
			Alias = 'user2', 
			CommunityNickname = 'user2', 
			TimeZoneSidKey ='Europe/Paris', 
			LocaleSidKey ='no_NO', 
			EmailEncodingKey ='UTF-8', 
			ProfileId = profileID.id, 
			LanguageLocaleKey ='no',
			ContactId=account2.PersonContactId
			//AccountId=account2.Id
		);
		insert user1; 
		insert user2;

		/*
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Community'];
		PermissionSetAssignment perm1 = new PermissionSetAssignment(AssigneeId = user1.Id, PermissionSetId = ps.Id);
		PermissionSetAssignment perm2 = new PermissionSetAssignment(AssigneeId = user2.Id, PermissionSetId = ps.Id);
		insert perm1; insert perm2;
		*/
		
	}

	@isTest static void testMethod1(){
		User user1 = [SELECT Id FROM User WHERE Alias=:'user1'];
		
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Community'];
		PermissionSetAssignment perm1 = new PermissionSetAssignment(AssigneeId = user1.Id, PermissionSetId = ps.Id);
		insert perm1;
		
		System.runAs(user1){
			List<HOT_Request__c> req1 = HOT_RequestListContoller.getRequestList();
			System.assertEquals(req1.size(), 1);
			System.assertEquals(req1[0].Subject__c, 'Subject 1');
		}
	}

	@isTest static void testMethod2(){
		User user2 = [SELECT Id FROM User WHERE Alias=:'user2'];
		
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Community'];
		PermissionSetAssignment perm2 = new PermissionSetAssignment(AssigneeId = user2.Id, PermissionSetId = ps.Id);
		insert perm2;
		
		System.runAs(user2){
			List<HOT_Request__c> req2 = HOT_RequestListContoller.getRequestList();
			System.assertEquals(req2.size(), 1);
			System.assertEquals(req2[0].Subject__c, 'Subject 2');
		}
	}
}