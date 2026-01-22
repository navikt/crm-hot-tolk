public with sharing class HOT_CheckPermissions {
    @AuraEnabled(cacheable=true)
    public static Boolean hasFreelancePermission() {
        Id userId = UserInfo.getUserId();

        List<PermissionSet> perms = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Community_Plus_User' LIMIT 1];

        if (perms.isEmpty()) {
            return false;
        }

        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetId = :perms[0].Id
            LIMIT 1
        ];

        return !assignments.isEmpty();
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasFormidlerAdminPermission() {
        Id userId = UserInfo.getUserId();

        List<PermissionSetGroup> groups = [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName = 'HOT_Tolk_Formidler_Admin_Gruppe'
            LIMIT 1
        ];

        if (groups.isEmpty()) {
            return false;
        }

        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetGroupId = :groups[0].Id
            LIMIT 1
        ];

        return !assignments.isEmpty();
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasFormidlerPermission() {
        Id userId = UserInfo.getUserId();

        List<PermissionSetGroup> groups = [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName = 'HOT_Tolk_Formidler_Gruppe'
            LIMIT 1
        ];

        if (groups.isEmpty()) {
            return false;
        }

        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetGroupId = :groups[0].Id
            LIMIT 1
        ];

        return !assignments.isEmpty();
    }
}