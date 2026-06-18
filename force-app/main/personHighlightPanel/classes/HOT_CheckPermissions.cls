public with sharing class HOT_CheckPermissions {
    // Lazy static user ID
    private static Id currentUserId;
    private static Id getCurrentUserId() {
        if (currentUserId == null) {
            currentUserId = UserInfo.getUserId();
        }
        return currentUserId;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getAllPermissions() {
        Id userId = getCurrentUserId();

        // Single SOQL to get all assignments for this user
        List<PermissionSetAssignment> assignments = [
            SELECT Id, PermissionSet.Name, PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
        ];

        // Initialize result map
        Map<String, Boolean> permissions = new Map<String, Boolean>{
            'hasFreelancePermission' => false,
            'hasTjenesteleverandorPermission' => false,
            'isFormidler' => false,
            'isFormidlerAdmin' => false,
            'isAdmin' => false
        };

        for (PermissionSetAssignment psa : assignments) {
            if (psa.PermissionSet != null) {
                if (psa.PermissionSet.Name == 'Create_Community_Plus_User') {
                    permissions.put('hasFreelancePermission', true);
                }
                if (psa.PermissionSet.Name == 'HOT_Admin') {
                    permissions.put('isAdmin', true);
                }
            }

            if (psa.PermissionSetGroup != null) {
                if (psa.PermissionSetGroup.DeveloperName == 'HOT_Tolk_Formidler_Gruppe') {
                    permissions.put('isFormidler', true);
                }
                if (psa.PermissionSetGroup.DeveloperName == 'HOT_Tolk_Formidler_Admin_Gruppe') {
                    permissions.put('isFormidlerAdmin', true);
                }
            }
        }

        if (permissions.get('hasFreelancePermission') && permissions.get('isAdmin')) {
            permissions.put('hasTjenesteleverandorPermission', true);
        }

        return permissions;
    }
}
