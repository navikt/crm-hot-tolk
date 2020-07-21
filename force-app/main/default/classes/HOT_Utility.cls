public without sharing class HOT_Utility {
	
	@AuraEnabled(cacheable = true)
    public static ServiceResource getServiceResource() {
		ServiceResource serviceResource = [SELECT Id, Name, ResourceType, IsActive, RelatedRecordId,
		(SELECT Id, ServiceTerritory.Name FROM ServiceResource.ServiceTerritories),
		(SELECT Id, Skill.MasterLabel FROM ServiceResource.ServiceResourceSkills)
		FROM ServiceResource WHERE RelatedRecordId =: UserInfo.getUserId()];
		return serviceResource;
	}
	
	@AuraEnabled(cacheable = true)
    public static Boolean checkAssignedPermissionSet(String permissionSetName) {
		List<PermissionSetAssignment> permsets = [SELECT Id, Assignee.Name FROM PermissionSetAssignment 
		WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name =: permissionSetName];
		//Or hotTolkFrilansGroup IN :PermissionSetGroup];
		return permsets.size()>0;
	}
	
	@AuraEnabled(cacheable = true)
    public static Boolean checkAssignedPermissionSetGroup(String permissionSetGroupName) {
		List<PermissionSetAssignment> permsets = [SELECT Id, Assignee.Name FROM PermissionSetAssignment 
		WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSetGroup.DeveloperName =: permissionSetGroupName];
		return permsets.size()>0;
	}


}
