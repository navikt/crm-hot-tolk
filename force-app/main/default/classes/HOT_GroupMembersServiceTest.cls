@IsTest
private class HOT_GroupMembersServiceTest {
    @testSetup
    static void setup() {
        List<PermissionSetGroup> permsetGroup = [
            SELECT Id, DeveloperName
            FROM PermissionSetGroup
            WHERE DeveloperName = 'HOT_Tolk_Test'
        ];
        if (permsetGroup.size() == 0) {
            PermissionSetGroup formidlerPermsetGroup = new PermissionSetGroup(
                DeveloperName = 'HOT_Tolk_Test',
                MasterLabel = 'HOT Tolk Test'
            );
            insert formidlerPermsetGroup;
            permsetGroup.add(formidlerPermsetGroup);
        }
        List<Group> grp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'HOT_group_4719_formidler'];
        if (grp.size() == 0) {
            Group formidlerGroup = new Group(DeveloperName = 'HOT_group_4719_formidler');
            insert formidlerGroup;
        }
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User formidler1 = HOT_TestDataFactory.createUser('User1', standardUserProfile);
        formidler1.Department = '4719';
        User formidler2 = HOT_TestDataFactory.createUser('User2', standardUserProfile);
        formidler2.Department = '4718';
        insert new List<User>{ formidler1, formidler2 };

        PermissionSetAssignment permsetAssignment1 = new PermissionSetAssignment(
            AssigneeId = formidler1.Id,
            PermissionSetGroupId = permsetGroup[0].Id
        );
        PermissionSetAssignment permsetAssignment2 = new PermissionSetAssignment(
            AssigneeId = formidler2.Id,
            PermissionSetGroupId = permsetGroup[0].Id
        );
        insert new List<PermissionSetAssignment>{ permsetAssignment1, permsetAssignment2 };
    }

    @IsTest
    static void addFormidler1Test() {
        Map<Id, User> users = new Map<Id, User>([SELECT Id, Department FROM User WHERE LastName IN ('User1', 'User2')]);

        Test.startTest();
        HOT_GroupMembersService.updateGroupMembers('HOT_Tolk_Test', 'HOT', 'formidler');
        Test.stopTest();

        Group grp = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'HOT_group_4719_formidler'];
        User formidler1 = [SELECT Id, Department FROM User WHERE LastName = 'User1' LIMIT 1];
        List<GroupMember> formidler1Member = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId = :grp.Id AND UserOrGroupId = :formidler1.Id
        ];
        System.assertEquals(true, formidler1Member.size() > 0, 'Could not set formidler 1 as member of group.');
    }

    @IsTest
    static void removeFormidler2Test() {
        User formidler2 = [SELECT Id, Department FROM User WHERE LastName = 'User2' LIMIT 1];
        Map<Id, User> users = new Map<Id, User>(new List<User>{ formidler2 });

        Group grp = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'HOT_group_4719_formidler'];
        GroupMember groupMember = new GroupMember(UserOrGroupId = formidler2.Id, GroupId = grp.Id);
        insert groupMember;

        List<GroupMember> formidler2Member = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId = :grp.Id AND UserOrGroupId = :formidler2.Id
        ];
        System.assertEquals(true, formidler2Member.size() > 0, 'Could not create group member.');

        Test.startTest();
        HOT_GroupMembersService.updateGroupMembers('HOT_Tolk_Test', 'HOT', 'formidler');
        Test.stopTest();

        formidler2Member = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId = :grp.Id AND UserOrGroupId = :formidler2.Id
        ];
        System.debug(formidler2Member);
        System.assertEquals(true, formidler2Member.size() == 0, 'Could not remove formidler 2 as member of group.');
    }

    @IsTest
    static void dontRemoveFormidler1() {
        User formidler1 = [SELECT Id, Department FROM User WHERE LastName = 'User1' LIMIT 1];
        Map<Id, User> users = new Map<Id, User>(new List<User>{ formidler1 });

        Group grp = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'HOT_group_4719_formidler'];
        GroupMember groupMember = new GroupMember(UserOrGroupId = formidler1.Id, GroupId = grp.Id);
        insert groupMember;

        List<GroupMember> formidler1Member = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId = :grp.Id AND UserOrGroupId = :formidler1.Id
        ];
        System.assertEquals(true, formidler1Member.size() > 0, 'Could not create group member.');

        Test.startTest();
        HOT_GroupMembersService.updateGroupMembers('HOT_Tolk_Test', 'HOT', 'formidler');
        Test.stopTest();

        formidler1Member = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId = :grp.Id AND UserOrGroupId = :formidler1.Id
        ];
        System.assertEquals(true, formidler1Member.size() > 0, 'Could not set formidler 1 as member of group.');
    }
}
