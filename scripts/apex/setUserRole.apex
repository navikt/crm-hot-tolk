User user = [SELECT Id FROM User WHERE Alias = 'UUser' LIMIT 1];
UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
user.UserRoleId = role.Id;
update user;