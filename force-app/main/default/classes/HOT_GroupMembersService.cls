public without sharing class HOT_GroupMembersService {
    public static void updateGroupMembers(String permissionSetGroupName, String prefix, String suffix) {
        Map<Id, User> users = getUsers(permissionSetGroupName);

        Map<String, String> groupNames = getGroupNames(prefix, suffix);
        Map<Id, Group> groupByUser = getGroupMembers(users, groupNames);

        Map<Id, groupMember> existingGroupMemberByUser = getExistingGroupMembers(groupNames.values());

        Set<GroupMember> membershipsToInsert = new Set<GroupMember>();
        Set<GroupMember> membershipsToDelete = new Set<GroupMember>(existingGroupMemberByUser.values());

        for (Id id : groupByUser.keySet()) {
            if (groupByUser.get(id) != null) {
                if (
                    existingGroupMemberByUser.get(id) != null &&
                    groupByUser.get(id).Id == existingGroupMemberByUser.get(id).GroupId
                ) {
                    membershipsToDelete.remove(existingGroupMemberByUser.get(id));
                } else {
                    GroupMember groupMember = new GroupMember(UserOrGroupId = id, GroupId = groupByUser.get(id).Id);
                    membershipsToInsert.add(groupMember);
                }
            }
        }

        if (membershipsToDelete.size() > 0) {
            delete new List<GroupMember>(membershipsToDelete);
        }
        if (membershipsToInsert.size() > 0) {
            insert new List<GroupMember>(membershipsToInsert);
        }
    }

    //Dette må vi ha ett eller annet sted, eventuelt hente det ut ved å sjekke gruppemedlemmer av grupper.
    private static Map<String, String> getDepartmentMap() {
        List<HOT_NewRegionNumber__mdt> regionMaps = [
            SELECT OldRegionNumber__c, NewRegionNumber__c
            FROM HOT_NewRegionNumber__mdt
        ];
        Map<String, String> departmentMap = new Map<String, String>();
        for (HOT_NewRegionNumber__mdt regionMap : regionMaps) {
            departmentMap.put(regionMap.OldRegionNumber__c, regionMap.NewRegionNumber__c);
        }
        return departmentMap;
    }

    private static Map<Id, String> getDepartmentNameByUser(Map<Id, User> users) {
        Map<String, String> departmentMap = getDepartmentMap();
        Map<Id, String> departmentNameByUser = new Map<Id, String>();
        for (User user : users.values()) {
            departmentNameByUser.put(user.Id, departmentMap.get(user.Department));
        }
        return departmentNameByUser;
    }

    private static Map<Id, User> getUsers(String permsetGroupName) {
        Id permsetGroupId = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :permsetGroupName LIMIT 1].Id;
        List<PermissionSetAssignment> permsetAssignments = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetGroupId = :permsetGroupId
        ];
        List<Id> userIds = new List<Id>();
        for (PermissionSetAssignment permsetAssignment : permsetAssignments) {
            userIds.add(permsetAssignment.AssigneeId);
        }
        Map<Id, User> usersWithPermset = new Map<Id, User>([SELECT Id, Department FROM User WHERE Id IN :userIds]);
        return usersWithPermset;
    }

    private static Map<String, String> getGroupNames(String prefix, String suffix) {
        Set<String> departments = new Set<String>(getDepartmentMap().values());
        Map<String, String> groupNames = new Map<String, String>();
        for (String dep : departments) {
            String groupName = '';
            if (prefix != null && prefix != '') {
                groupName += prefix + '_';
            }
            groupName += 'group_' + dep;
            if (suffix != null && suffix != '') {
                groupName += '_' + suffix;
            }
            groupNames.put(dep, groupName);
        }
        return groupNames;
    }

    private static Map<Id, GroupMember> getExistingGroupMembers(List<String> groupNames) {
        Map<Id, Group> groups = new Map<Id, Group>([SELECT Id FROM Group WHERE DeveloperName IN :groupNames]);
        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId IN :groups.keySet()
        ];
        Map<Id, GroupMember> groupMemberByUser = new Map<Id, GroupMember>();
        for (GroupMember groupMember : groupMembers) {
            groupMemberByUser.put(groupMember.UserOrGroupId, groupMember);
        }
        return groupMemberByUser;
    }

    private static Map<Id, Group> getGroupMembers(Map<Id, User> users, Map<String, String> groupNames) {
        Map<Id, String> departmentNumberByUser = getDepartmentNameByUser(users);
        Map<Id, Group> groups = new Map<Id, Group>(
            [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNames.values()]
        );
        Map<String, Id> groupByName = new Map<String, Id>();
        for (Group grp : groups.values()) {
            groupByName.put(grp.DeveloperName, grp.Id);
        }
        Map<Id, Group> groupByUser = new Map<Id, Group>();
        for (Id id : users.keySet()) {
            groupByUser.put(id, groups.get(groupByName.get(groupNames.get(departmentNumberByUser.get(id)))));
        }
        return groupByUser;
    }
}
