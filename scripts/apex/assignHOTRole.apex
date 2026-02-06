try {
    UserRole hotRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'HOT' LIMIT 1];

    User adminUser = [SELECT Id, UserRoleId FROM User WHERE Alias = 'UUser' LIMIT 1];

    adminUser.UserRoleId = hotRole.Id;
    update adminUser;

    System.debug('Success: Assigned Role HOT to user UUser.');

} catch (Exception e) {
    System.debug('Error: Could not assign role. Ensure the Role "HOT" is deployed to the org.');
    System.debug('Details: ' + e.getMessage());
}