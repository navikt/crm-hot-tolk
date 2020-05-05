public with sharing class HOT_checkAssignedPermissionSet {
	
	@AuraEnabled(cacheable = true)
    public static Boolean checkAssignedPermissionSet(String permissionSetName) {
		List<PermissionSetAssignment> permsets = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name =: permissionSetName];
		return permsets.size()>0;
	}
}
