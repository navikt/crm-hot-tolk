@isTest
public with sharing class DisableFreelanceUsersSchedulableTest {
    @TestSetup
    static void setup() {
    }
    @isTest
    static void testBatchClass() {
        Profile profile=[SELECT Id, Name FROM Profile WHERE Name='NAV Samhandler' LIMIT 1];

        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'UUser Customer Person Account' LIMIT 1];
       
        Account acc=HOT_TestDataFactory.createAccount(false);
        insert acc;
        acc.Name='Wader';
        update acc;

        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'Doe';
        con.Email = 'johndoe@test.com';
        con.AccountId = acc.Id;
        insert con;

        Account acco=[SELECT Id FROM Account WHERE Name='Wader' LIMIT 1];
        // User user = HOT_TestDataFactory.createUser(profile, acco);
        // user.ContactId = con.Id;
        // user.UserRoleId = role.Id;
        // insert user;
        createUser(profile.Id, role.Id, con.Id);

        User user=[SELECT Id FROM User LIMIT 1];

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource1;
        resource1.HOT_IsFreelanceInterpreter__c=true;
        update resource1;

        PermissionSet permissionsetFreelance=[SELECT Id, Name FROM PermissionSet WHERE Name='HOT_Tolk_Frilans' LIMIT 1];
      
        assignPermissionSet(user.Id, permissionsetFreelance.Id);

        Test.startTest();
        
        DisableFreelanceUsersSchedulable schedulable = new DisableFreelanceUsersSchedulable();
        String sch = '0 0 23 * * ?'; // Schedule the batch to run daily at 11 PM
        system.schedule('Test schedule', sch, schedulable);
        
        Test.stopTest();
        
        // Verify that the batch class has correctly disabled the ServiceResource records and updated the affected users' ProfileId
        ServiceResource testServiceResource = [SELECT IsActive FROM ServiceResource WHERE Id = :resource1.Id];
        User testUser = [SELECT ProfileId FROM User WHERE Id = :user.Id];
        DisableFreelanceUsersSchedulable.oneYearAgo = Date.today();
        
        System.assert(!testServiceResource.IsActive);
        System.assertNotEquals(profile.Id, testUser.ProfileId);
        
    }
    @future
public static void assignPermissionSet(Id userId, Id permissionsetId) {
    insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionsetId);
}
@future
public static void createUser(Id profile, Id role, Id contact) {
   
);
}



}