@isTest
private class HOT_UtilityTest{

	@testSetup static void setup(){
		ServiceResource serviceresourceObj = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceresourceObj;
	}

	@isTest static void testGetServiceResource() {
		ServiceResource serviceResource = HOT_Utility.getServiceResource();
		System.assertEquals(UserInfo.getUserId(), serviceResource.RelatedRecordId);
	}

	@isTest static void testCheckAssignedPermissionSet() {
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Ansatt'];
		PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
		insert permissionSetAssignment;
		
		Boolean hasPermissionSet = HOT_Utility.checkAssignedPermissionSet('HOT_Tolk_Ansatt');
		System.assertEquals(true, hasPermissionSet);
	}
}