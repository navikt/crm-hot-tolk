public with sharing class HOT_GroupMembersService {
	
	//Dette må vi ha ett eller annet sted, eventuelt hente det ut ved å sjekke gruppemedlemmer av grupper.
	public static Map<String, String> getDepartmentMap(){
		Map<String, String> departmentMap = new Map<String, String>();
		departmentMap.put('4701', '4701');
		departmentMap.put('4703', '4703');
		departmentMap.put('4706', '4706');
		departmentMap.put('4715', '4715');
		departmentMap.put('4716', '4716');
		departmentMap.put('4718', '4718');
		departmentMap.put('4719', '4719');
		departmentMap.put('4709', '47001');
		departmentMap.put('4710', '47001');
		departmentMap.put('4712', '47002');
		departmentMap.put('4714', '47002');
		departmentMap.put('4704', '47003');
		departmentMap.put('4705', '47003');
		departmentMap.put('4707', '47004');
		departmentMap.put('4708', '47004');
		departmentMap.put('4711', '47005');
		return departmentMap;
	}

	public static Map<Id, String> getDepartmentNameByUser(Map<Id, User> users){
		Map<String, String> departmentMap = getDepartmentMap();
		Map<Id, String> departmentNameByUser = new Map<Id, String>();
		for(User user:users.values()){
			departmentNameByUser.put(user.Id, departmentMap.get(user.Department));
		}
		return departmentNameByUser;
	}

	public static Map<Id, User> filterUsers(Map<Id, User> users, String permsetGroupName){
		Id permsetGroupId = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :permsetGroupName LIMIT 1].Id;
		List<PermissionSetAssignment> permsetAssignments = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId = :permsetGroupId AND AssigneeId IN :users.keySet()];
		Map<Id, User> usersWithPermset = new Map<Id, User>();
		for(PermissionSetAssignment permsetAssignment:permsetAssignments){
			usersWithPermset.put(permsetAssignment.AssigneeId, users.get(permsetAssignment.AssigneeId));
		}
		return usersWithPermset;
	}

	public static Map<String, String> getGroupNames(String role){
		Set<String> departments = new Set<String>(getDepartmentMap().values());
		Map<String, String> groupNames = new Map<String, String>();
		for(String dep:departments){
			String groupName = 'HOT_group_' + dep + '_' + role;
			groupNames.put(dep, groupName);
		}
		return groupNames;
	}

	public static Map<Id, GroupMember> getExistingGroupMembers(List<String> groupNames){
		Map<Id, Group> groups = new Map<Id, Group>([SELECT Id FROM Group WHERE Name IN :groupNames]);
		List<GroupMember> groupMembers = [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :groups.keySet()];
		Map<Id, GroupMember> groupMemberByUser = new Map<Id, GroupMember>();
		for(GroupMember groupMember:groupMembers){
			groupMemberByUser.put(groupMember.UserOrGroupId, groupMember);
		}
		return groupMemberByUser;
	}

	public static Map<Id, Group> getGroupMembers(Map<Id, User> users, Map<String, String> groupNames){
		Map<Id, String> departmentNumberByUser = getDepartmentNameByUser(users);
		Map<Id, Group> groups = new Map<Id, Group>([SELECT Id, Name FROM Group WHERE Name IN :groupNames.values()]);
		Map<String, Id> groupByName = new Map<String, Id>();
		for(Group grp:groups.values()){
			groupByName.put(grp.Name, grp.Id);
		}
		Map<Id, Group> groupByUser = new Map<Id, Group>();
		for(Id id:users.keySet()){
			groupByUser.put(id, groups.get(groupByName.get(groupNames.get(departmentNumberByUser.get(id)))));
		}
		return groupByUser;
	}

	public static void updateGroupMembers(Map<Id, User> users0, String permissionSetGroupName, String role){

		Map<Id, User> users = filterUsers(users0, permissionSetGroupName);

		Map<String, String> groupNames = getGroupNames(role);
		Map<Id, Group> groupByUser = getGroupMembers(users, groupNames);

		Map<Id, groupMember> existingGroupMemberByUser = getExistingGroupMembers(groupNames.values());

		Set<GroupMember> membershipsToInsert = new Set<GroupMember>();
		Set<GroupMember> membershipsToDelete = new Set<GroupMember>(existingGroupMemberByUser.values());

		for(Id id:groupByUser.keySet()){
			System.debug(id);
			System.debug(groupByUser);
			System.debug(groupByUser.get(id));
			if(groupByUser.get(id) != null){
				if(existingGroupMemberByUser.get(id) != null && groupByUser.get(id).Id == existingGroupMemberByUser.get(id).GroupId){
					membershipsToDelete.remove(existingGroupMemberByUser.get(id));
				}
				else{
					GroupMember groupMember = new GroupMember(UserOrGroupId = id, GroupId = groupByUser.get(id).Id);
					membershipsToInsert.add(groupMember);
				}
			}
		}

		if(membershipsToDelete.size()>0){
			delete new List<GroupMember>(membershipsToDelete);
		}
		if(membershipsToInsert.size()>0){
			insert new List<GroupMember>(membershipsToInsert);
		}
	}

}
