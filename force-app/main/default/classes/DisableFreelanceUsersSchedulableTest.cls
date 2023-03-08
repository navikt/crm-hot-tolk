@isTest
public with sharing class DisableFreelanceUsersSchedulableTest {
    @TestSetup
    static void setup() {
    }
    @isTest
    static void testBatchClass() {
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'UUser Customer Person Account' LIMIT 1];
        Profile profile=[SELECT Id, Name FROM Profile WHERE Name='NAV Samhandler' LIMIT 1];
        Person__c person=HOT_TestDataFactory.createPerson();
        insert person;
        Account acc=HOT_TestDataFactory.createAccount(false);
        insert acc;
        acc.Name='Wader';
        acc.CRM_Person__c=person.Id;
        update acc;

        createUser();

        User user=[SELECT Id FROM User order by Id DESC limit 1];

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
public static void createUser() {
    Account acco=[SELECT Id, PersonContactId FROM Account WHERE Name='Wader' LIMIT 1];
     UserRole role = [SELECT Id FROM UserRole WHERE Name = 'UUser Customer Person Account' LIMIT 1];
    Profile profile=[SELECT Id, Name FROM Profile WHERE Name='NAV Samhandler' LIMIT 1];
     Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'Doe';
        con.Email = 'johndoe@test.com';
        con.AccountId = acco.Id;
        insert con;
   
         User user = HOT_TestDataFactory.createUser(profile, acco);
         user.ContactId = con.Id;
         user.UserRoleId = role.Id;
         insert user;
}
}