@IsTest
private class HOT_ServiceResourceHandlerTest {
    @testSetup
    static void setup() {
        TestDataFactory.getPublicGroup('HMS Troms og Finmark', 'group_4719');
        TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'ServiceResource');
        TestDataFactory.getPublicGroup('HMS Nordland', 'group_4718');
        TestDataFactory.getQueue('HMS Nordland', 'queue_4718', 'ServiceResource');

        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        admin.Department = '4718';
        insert admin;

        System.runAs(admin) {
            Profile communityProfile = [
                SELECT Name
                FROM Profile
                WHERE
                    Name = 'Personbruker Login'
                    OR Name = 'Trial Customer Portal User'
                    OR Name = 'Customer Community User'
                LIMIT 1
            ];
            DefaultCommunityProfile__c defaultCommunityProfile = new DefaultCommunityProfile__c(
                DefaultProfile__c = communityProfile.Name,
                DefaultPermissionSet__c = 'CRM_ManageAsyncRequests',
                DefaultCommunityPlusProfile__c = 'Customer Community User',
                DefaultCommunityPlusPermissionSetGroup__c = 'Test'
            );
            insert defaultCommunityProfile;

            Person__c person = new Person__c();
            person.INT_Confidential__c = 'Ugradert';
            person.INT_FirstName__c = 'Freelance';
            person.INT_LastName__c = 'Tolk';
            person.Name = '01011800001';
            insert person;

            Account account = [SELECT Id, OwnerId FROM Account WHERE LastName = :'Tolk'];
            account.OwnerId = admin.Id;
            update account;

            OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
            insert operatingHours;
            ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
            serviceTerritory.HOT_DeveloperName__c = 'Nordland';
            insert serviceTerritory;
        }

    }

    @IsTest
    static void CreateServiceResourceTest() {
        Test.startTest();
        CommunityUsersService.createCommunityPlusUser(new List<String>{ '01011800001' });
        Test.stopTest();

        User officeUser = TestDataFactory_Community.getUsers(1, 'System Administrator', true, true)[0];
        System.runAs(officeUser) {
            HOT_ServiceResourceHandler.createServiceResource(new List<String>{ '01011800001' }, true, 'Nordland');
        }

        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
        List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id FROM ServiceTerritoryMember];
        List<HOT_Resource__c> resources = [SELECT Id FROM HOT_Resource__c];
        List<HOT_ResourceMember__c> resourceMembers = [SELECT Id FROM HOT_ResourceMember__c];
        System.assertEquals(1, serviceResources.size());
        System.assertEquals(1, serviceTerritoryMembers.size());
        System.assertEquals(1, resources.size());
        System.assertEquals(1, resourceMembers.size());
    }
    @IsTest
    static void CreateServiceResourceAutoTest() {
        Test.startTest();
        List<User> users = CommunityUsersService.createCommunityPlusUser(new List<String>{ '01011800001' });
        Test.stopTest();

        User officeUser = [
            SELECT Id, Department, LastName, UserRoleId
            FROM User
            WHERE Department = '4718' AND LastName = 'admin'
        ];
        System.runAs(officeUser) {
            HOT_ServiceResourceHandler.createServiceResource(new List<String>{ '01011800001' }, true, 'AUTO');
        }

        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
        List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id FROM ServiceTerritoryMember];
        List<HOT_Resource__c> resources = [SELECT Id FROM HOT_Resource__c];
        List<HOT_ResourceMember__c> resourceMembers = [SELECT Id FROM HOT_ResourceMember__c];
        System.assertEquals(1, serviceResources.size());
        System.assertEquals(1, serviceTerritoryMembers.size());
        System.assertEquals(1, resources.size());
        System.assertEquals(1, resourceMembers.size());
    }
}
