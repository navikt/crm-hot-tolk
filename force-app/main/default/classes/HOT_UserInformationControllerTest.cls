@isTest
private class HOT_UserInformationControllerTest{

	@testSetup static void setup(){
		
		Profile communityProfile = [SELECT Id FROM Profile WHERE Name='Customer Community Login User' LIMIT 1];
		
		Person__c person = HOT_TestDataFactory.createPerson();
		person.INT_KrrEmail__c = 'getPersonTest@nav.no';
		person.HOT_WorkplaceInterpreter__c = true;
		insert person;
		Account account = HOT_TestDataFactory.createAccount(true);
		account.LastName='Tester';
		account.CRM_Person__c = person.Id;
		insert account;
		account = [SELECT Id, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c FROM Account WHERE LastName =: account.LastName];

		User admin = [SELECT Id FROM User WHERE Alias = 'UUser' LIMIT 1];
		setRoleOnUser(admin);

		User user = HOT_TestDataFactory.createUser(communityProfile, account);
		user.Alias = 'userTest';
		user.Username = 'HOT_testuser1@nav.hot.no';
		user.CommunityNickname = 'userTest';
		insert user; 
	}

	static void setRoleOnUser(User user){
		UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
		user.UserRoleId = role.Id;
		update user;
	}

	@isTest static void getPersonPhoneEmailTest() {
		User user = [SELECT Id FROM User WHERE Username = 'HOT_testuser1@nav.hot.no'];
		System.runAs(user){
			Person__c person = HOT_UserInformationController.getPersonPhoneEmail();
			System.assertEquals('getpersontest@nav.no', person.INT_KrrEmail__c);
		}
	}
	@isTest static void getPersonTest() {
		User user = [SELECT Id FROM User WHERE Username = 'HOT_testuser1@nav.hot.no'];
		System.runAs(user){
			Person__c person = HOT_UserInformationController.getPerson();
			System.assertEquals(true, person.HOT_WorkplaceInterpreter__c);
		}
	}

}