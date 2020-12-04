@isTest
private class HOT_WorkOrderListControllerTest{


	@testSetup static void setup(){

        Profile communityProfile = [SELECT Name FROM Profile WHERE Name='Personbruker Login' OR Name='Trial Customer Portal User' LIMIT 1];
        DefaultCommunityProfile__c defaultCommunityProfile=new DefaultCommunityProfile__c(DefaultProfile__c=communityProfile.Name, DefaultPermissionSet__c='CRM_ManageAsyncRequests',
        DefaultCommunityPlusProfile__c = 'Trial Customer Portal User', DefaultCommunityPlusPermissionSetGroup__c = 'Test');
		insert defaultCommunityProfile;
		
		User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		if(admin.UserRoleId == null){
			UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
			admin.UserRoleId = role.Id;
			update admin;
		}

		Person__c person = HOT_TestDataFactory.createPerson();
		person.INT_KrrEmail__c = 'getPersonTest@nav.no';
		person.HOT_WorkplaceInterpreter__c = true;
		person.INT_Confidential__c = 'Ugradert';
		person.INT_FirstName__c = 'Tolk';
		person.INT_LastName__c = 'Bruker';
		insert person;

		Account account = [SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c FROM Account WHERE LastName =: 'Bruker'];
		account.OwnerId = admin.Id;
		update account;


		User user = HOT_TestDataFactory.createUser(communityProfile, account);
		user.Alias = 'userTest';
		user.Username = 'HOT_testuser1@nav.hot.no';
		user.CommunityNickname = 'userTest';
		insert user; 

		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('WorkOrderListController', workType);
		request.Account__c = account.Id;
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
		insert serviceResource;

		ServiceAppointment serviceAppointments = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id LIMIT 1];
		AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointments.Id, serviceResource.Id);
		insert assignedResource;
	}

	@isTest static void getMyWorkOrdersTest() {
		User user = [SELECT Id FROM User WHERE Alias = 'userTest'];

		System.runAs(user){
			List<WorkOrder> workOrders = HOT_WorkOrderListController.getMyWorkOrders();
			System.assertEquals(1, workOrders.size());
		}
	}
	@isTest static void getWorkOrdersFromRequestTest() {
		User user = [SELECT Id, AccountId FROM User WHERE Alias = 'userTest'];
		HOT_Request__c request = [SELECT Id, Name FROM HOT_Request__c WHERE Account__c = :user.AccountId LIMIT 1];
		System.runAs(user){
			List<WorkOrder> workOrders = HOT_WorkOrderListController.getWorkOrdersFromRequest((String) request.Name);
			System.assertEquals(1, workOrders.size());
		}
	}
}