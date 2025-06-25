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

    @IsTest
    static void UpdateServiceResourceAutoTest() {
        Test.startTest();
        List<User> users = CommunityUsersService.createCommunityPlusUser(new List<String>{ '01011800001' });
        List<User> test = new List<User>();
        User user = [SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department, IsActive
            FROM User
            WHERE id = :UserInfo.getUserId() LIMIT 1];
        test.add(user);
        User officeUser = [
            SELECT Id, Department, LastName, UserRoleId
            FROM User
            WHERE Department = '4718' AND LastName = 'admin'
        ];
        System.runAs(officeUser) {
            //Testing the new service resource path
            HOT_ServiceResourceHandler.updateServiceResource(new List<String>{ '01011800001' }, true, 'AUTO');
        }
        //Verifying the new service resource path
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource];
        List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id FROM ServiceTerritoryMember];
        List<HOT_Resource__c> resources = [SELECT Id FROM HOT_Resource__c];
        List<HOT_ResourceMember__c> resourceMembers = [SELECT Id FROM HOT_ResourceMember__c];
        System.assertEquals(1, serviceResources.size());
        System.assertEquals(1, serviceTerritoryMembers.size());
        System.assertEquals(1, resources.size());
        System.assertEquals(1, resourceMembers.size());

        //testing and verifying the deactivate and re-activate resource path
        //Deactivate user, verify service resource is deactivated, then re-activate user and confirm service resource is now active
        ServiceResource newSR = [SELECT Id, IsActive FROM ServiceResource WHERE id = :user.id LIMIT 1];
        System.assertEquals(true, newSR.IsActive, 'Service Resource was not active');
        user.IsActive = false;
        update user;
        User deactivatedUser = [SELECT Id, IsActive FROM User WHERE id = :user.id LIMIT 1];
        ServiceResource deactivatedSR = [SELECT Id, IsActive FROM ServiceResource WHERE id = :newSr.id LIMIT 1];
        System.assertEquals(false, deactivatedSR.IsActive, 'De-activating did not make the Service Resource Inactive');
        System.assertEquals(false, deactivatedUser.IsActive, 'De-activating did not make the User Inactive');
        user.IsActive = true;
        update user;
        ServiceResource activateSR = [SELECT Id, IsActive FROM ServiceResource WHERE id = :newSr.id LIMIT 1];
        System.assertEquals(true, activateSR.IsActive, 'Re-activating did not make the Service Resource Active');

        //testing and verifying deactivating SR manually, then running update with correct path
        System.runAs(officeUser) {
            //Testing the existing service with inactive resource path
            HOT_ServiceResourceHandler.updateServiceResource(test, true, 'AUTO');
            ServiceResource newSR2 = [SELECT Id, IsActive FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() LIMIT 1];
            System.assertEquals(true, newSR2.IsActive, 'Running the future job did not make a service resource');
            newSR2.IsActive = false;
            update newSR2;
            ServiceResource deactivatedSR2 = [SELECT Id, IsActive FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() LIMIT 1];
            System.assertEquals(false, deactivatedSR2.IsActive, 'De-activating did not make the Service Resource Inactive');
            HOT_ServiceResourceHandler.updateServiceResourceFuture(test);
        }
        test.stopTest();
        ServiceResource activateSR2 = [SELECT Id, IsActive FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() LIMIT 1];
        System.assertEquals(true, activateSR2.IsActive, 'Re-running did not make the Service Resource Active');
    }
}
