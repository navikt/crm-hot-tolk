// 1. Identify the Target User and Group
String targetUserName = 'User User';
String groupDevName = 'HOT_Tolk_Admin';

try {
    // 2. Query for the 'User User' (Limit 1 for safety)
    User targetUser = [SELECT Id FROM User WHERE Name = :targetUserName AND IsActive = true LIMIT 1];
    
    // 3. Query for the Public Group ID
    Group targetGroup = [SELECT Id FROM Group WHERE DeveloperName = :groupDevName AND Type = 'Regular' LIMIT 1];

    // 4. Check if membership already exists to avoid errors
    List<GroupMember> existing = [SELECT Id FROM GroupMember 
                                  WHERE GroupId = :targetGroup.Id 
                                  AND UserOrGroupId = :targetUser.Id];

    if (existing.isEmpty()) {
        GroupMember gm = new GroupMember(
            GroupId = targetGroup.Id,
            UserOrGroupId = targetUser.Id
        );
        insert gm;
        System.debug('✅ Success: ' + targetUserName + ' added to ' + groupDevName);
    } else {
        System.debug('ℹ️ Info: User is already a member of this group.');
    }

} catch (QueryException e) {
    System.debug('❌ Error: Could not find the User or the Group. Check your DeveloperName.');
} catch (Exception e) {
    System.debug('❌ Unexpected Error: ' + e.getMessage());
}