public with sharing class HOT_Utility {
	
	@AuraEnabled(cacheable = true)
    public static ServiceResource getServiceResource() {
		ServiceResource serviceResource = [SELECT Id, Name, ResourceType, IsActive, 
		(SELECT Id, ServiceTerritoryId FROM ServiceResource.ServiceTerritories)
		FROM ServiceResource WHERE RelatedRecordId =: UserInfo.getUserId()];
		return serviceResource;
	}
	
	@AuraEnabled(cacheable = true)
    public static Boolean checkAssignedPermissionSet(String permissionSetName) {
		List<PermissionSetAssignment> permsets = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name =: permissionSetName];
		return permsets.size()>0;
	}
}
