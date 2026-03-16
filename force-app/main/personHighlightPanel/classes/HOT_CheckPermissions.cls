public with sharing class HOT_CheckPermissions {
    @AuraEnabled(cacheable=true)
    public static Boolean hasFreelancePermission() {
        return [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'Create_Community_Plus_User'
                LIMIT 1
            ]
            .size() > 0;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasFormidlerAdminPermission() {
        return [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE
                    AssigneeId = :UserInfo.getUserId()
                    AND PermissionSetGroup.DeveloperName = 'HOT_Tolk_Formidler_Admin_Gruppe'
                LIMIT 1
            ]
            .size() > 0;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasFormidlerPermission() {
        return [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE
                    AssigneeId = :UserInfo.getUserId()
                    AND PermissionSetGroup.DeveloperName = 'HOT_Tolk_Formidler_Gruppe'
                LIMIT 1
            ]
            .size() > 0;
    }
    @AuraEnabled(cacheable=true)
    public static Boolean hasHotAdminPermission() {
        return [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'HOT_Admin'
                LIMIT 1
            ]
            .size() > 0;
    }
}
