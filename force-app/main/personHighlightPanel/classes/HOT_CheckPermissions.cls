public with sharing class HOT_CheckPermissions {
    @AuraEnabled(cacheable=true)
    public static Boolean hasFreelancePermission() {
        string userId = UserInfo.getUserId();
        string permissionId = [SELECT id FROM permissionSet WHERE Name = 'Create_Community_Plus_User' LIMIT 1].id;
        if (!String.isBlank(permissionID)) {
            try {
                string assignedId = [
                    SELECT id
                    FROM permissionSetAssignment
                    WHERE assigneeId = :userId AND permissionSetId = :permissionId
                    LIMIT 1
                ]
                .id;
                if (assignedId != null) {
                    return true;
                }
            } catch (exception e) {
                //Does not have permission
            }
        }
        return false;
    }
}
