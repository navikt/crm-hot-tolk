@isTest
public without sharing class HOT_CheckPermissionsTest {
    private static Id testUserId;

    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User user = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
            emailencodingkey = 'UTF-8',
            lastname = 'Testing',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            country = 'Norway',
            IsActive = true,
            timezonesidkey = 'Europe/Paris',
            username = 'HOT_testaccount@nav.hot.no'
        );
        insert user;

        testUserId = user.Id;
    }
    @isTest
    static void HOT_CheckFreelanceTest() {
        Boolean hasPermission;
        Test.startTest();
        //Run as system admin user without permission set
        hasPermission = HOT_CheckPermissions.hasFreelancePermission();
        system.assertEquals(false, hasPermission, 'Expected false for user.');

        //Assign permission set and run again
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Community_Plus_User'];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert permissionSetAssignment;

        hasPermission = HOT_CheckPermissions.hasFreelancePermission();
        system.assertEquals(true, hasPermission, 'Expected true for user.');
        Test.stopTest();
    }
    @isTest
    static void HOT_CheckFormidlerTest() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'TestUser' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Boolean hasPermission = HOT_CheckPermissions.hasFormidlerPermission();
            System.assertEquals(false, hasPermission, 'Expected false for user.');

            PermissionSetGroup psg = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE DeveloperName = 'HOT_Tolk_Formidler_Gruppe'
                LIMIT 1
            ];

            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetGroupId = psg.Id);

            hasPermission = HOT_CheckPermissions.hasFormidlerPermission();
            System.assertEquals(true, hasPermission, 'Expected true for user.');

            Test.stopTest();
        }
    }

    @isTest
    static void HOT_CheckFormidlerAdminPermissionTest() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'TestUser'];

        System.runAs(testUser) {
            Boolean hasPermission;

            Test.startTest();

            hasPermission = HOT_CheckPermissions.hasFormidlerAdminPermission();
            System.assertEquals(false, hasPermission, 'Expected false when user does not have admin permission group');

            PermissionSetGroup psg = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE DeveloperName = 'HOT_Tolk_Formidler_Admin_Gruppe'
                LIMIT 1
            ];

            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetGroupId = psg.Id);

            hasPermission = HOT_CheckPermissions.hasFormidlerAdminPermission();
            System.assertEquals(true, hasPermission, 'Expected true when user has admin permission group');
            Test.stopTest();
        }
    }
}
