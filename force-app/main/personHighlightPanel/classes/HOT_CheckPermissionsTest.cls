@isTest
public without sharing class HOT_CheckPermissionsTest {
    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];

        User user = new User(
            alias = 'tuser',
            email = 'hot_testaccount@nav.no',
            emailencodingkey = 'UTF-8',
            lastname = 'Testing',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'Europe/Paris',
            username = 'hot_testaccount+' + System.currentTimeMillis() + '@nav.no'
        );
        insert user;
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
    }

    @isTest
    static void getAllPermissions_defaultsAreFalse() {
        User u = getTestUser();

        System.runAs(u) {
            Test.startTest();
            Map<String, Boolean> perms = HOT_CheckPermissions.getAllPermissions();
            Test.stopTest();

            System.assertEquals(false, perms.get('hasFreelancePermission'));
            System.assertEquals(false, perms.get('isFormidler'));
            System.assertEquals(false, perms.get('isFormidlerAdmin'));
            System.assertEquals(false, perms.get('isAdmin'));
        }
    }

    @isTest
    static void getAllPermissions_freelancePermissionSet() {
        User u = getTestUser();

        PermissionSet ps = null;
        List<PermissionSet> psets = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = 'Create_Community_Plus_User'
            LIMIT 1
        ];
        if (!psets.isEmpty()) {
            ps = psets[0];
        }

        System.runAs(u) {
            Test.startTest();

            Map<String, Boolean> beforePerms = HOT_CheckPermissions.getAllPermissions();
            System.assertEquals(false, beforePerms.get('hasFreelancePermission'));

            if (ps != null) {
                insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

                Map<String, Boolean> afterPerms = HOT_CheckPermissions.getAllPermissions();
                System.assertEquals(true, afterPerms.get('hasFreelancePermission'));
            }

            Test.stopTest();
        }
    }

    @isTest
    static void getAllPermissions_adminPermissionSet() {
        User u = getTestUser();

        PermissionSet ps = null;
        List<PermissionSet> psets = [SELECT Id, Name FROM PermissionSet WHERE Name = 'HOT_Admin' LIMIT 1];
        if (!psets.isEmpty()) {
            ps = psets[0];
        }

        System.runAs(u) {
            Test.startTest();

            Map<String, Boolean> beforePerms = HOT_CheckPermissions.getAllPermissions();
            System.assertEquals(false, beforePerms.get('isAdmin'));

            if (ps != null) {
                insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

                Map<String, Boolean> afterPerms = HOT_CheckPermissions.getAllPermissions();
                System.assertEquals(true, afterPerms.get('isAdmin'));
            }

            Test.stopTest();
        }
    }

    @isTest
    static void getAllPermissions_formidlerGroups_areFalseWhenNotAssigned() {
        User u = getTestUser();

        System.runAs(u) {
            Test.startTest();
            Map<String, Boolean> perms = HOT_CheckPermissions.getAllPermissions();
            Test.stopTest();

            System.assertEquals(false, perms.get('isFormidler'));
            System.assertEquals(false, perms.get('isFormidlerAdmin'));
        }
    }
}
