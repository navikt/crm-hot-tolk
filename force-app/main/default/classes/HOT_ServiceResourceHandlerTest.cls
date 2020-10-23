@isTest
private class HOT_ServiceResourceHandlerTest{

	@testSetup static void setup(){
        Profile communityProfile = [SELECT Name FROM Profile WHERE Name='Personbruker Login' OR Name='Trial Customer Portal User' LIMIT 1];
        DefaultCommunityProfile__c defaultCommunityProfile=new DefaultCommunityProfile__c(DefaultProfile__c=communityProfile.Name, DefaultPermissionSet__c='CRM_ManageAsyncRequests',
        DefaultCommunityPlusProfile__c = 'Trial Customer Portal User', DefaultCommunityPlusPermissionSetGroup__c = 'Test');
        insert defaultCommunityProfile;

		
		Person__c person = new Person__c();
		person.INT_Confidential__c = 'Ugradert';
		person.INT_FirstName__c = 'Freelance';
		person.INT_LastName__c = 'Tolk';
		person.Name = '01011800001';
		insert person;

		Account account = [SELECT Id, OwnerId FROM Account WHERE LastName =: 'Tolk'];
		account.OwnerId = UserInfo.getUserId();
		update account;

		OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
		insert operatingHours;
		ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
		insert serviceTerritory;

		

	}

	@isTest static void CreateServiceResourceTest() {
		Test.startTest();
			CommunityUsersService.createCommunityPlusUser(new List<String>{ '01011800001' });	
		Test.stopTest();

        User officeUser = TestDataFactory_Community.getUsers(1, 'System Administrator', true, true)[0];
        System.runAs(officeUser) {
			HOT_ServiceResourceHandler.createServiceResource(new List<String>{ '01011800001' }, true, 'Service_Territory_Name');
		}

		List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
		System.assertEquals(1, serviceResources.size());

	}

}