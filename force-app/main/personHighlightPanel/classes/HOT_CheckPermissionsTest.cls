@isTest
public without sharing class HOT_CheckPermissionsTest {
    @isTest
    static void HOT_CheckFreelanceTest() {
        Boolean hasPermission;

        //Run as system admin user without permission set
        hasPermission = HOT_CheckPermissions.hasFreelancePermission();
        system.assertEquals(false, hasPermission, 'Expected false for user permission.');

        //Assign permission set and run again
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Community_Plus_User'];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert permissionSetAssignment;

        hasPermission = HOT_CheckPermissions.hasFreelancePermission();
        system.assertEquals(true, hasPermission, 'Expected true for user permission.');
    }
}
