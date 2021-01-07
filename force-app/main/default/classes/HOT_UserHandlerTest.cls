@isTest
private class HOT_UserHandlerTest{

	@testSetup static void setup(){
        Profile communityProfile = [SELECT Name FROM Profile WHERE Name='Personbruker Login' OR Name='Trial Customer Portal User' LIMIT 1];
        DefaultCommunityProfile__c defaultCommunityProfile=new DefaultCommunityProfile__c(DefaultProfile__c=communityProfile.Name, DefaultPermissionSet__c='CRM_ManageAsyncRequests',
        DefaultCommunityPlusProfile__c = 'Trial Customer Portal User', DefaultCommunityPlusPermissionSetGroup__c = 'Test');
        insert defaultCommunityProfile;
	}

	@isTest static void createAnsattTolk() {
		List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		if(profiles.size()>0){
			Profile profile = profiles[0];
			User user = HOT_TestDataFactory.createUser('Testing', profile);
			Test.startTest();
			insert user;
			Test.stopTest();

			List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
			System.assertEquals(1, serviceResources.size(), 'Could not create ServiceResource');
		}
	}

}