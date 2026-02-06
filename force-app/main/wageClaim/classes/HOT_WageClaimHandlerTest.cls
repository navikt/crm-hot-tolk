@IsTest
private class HOT_WageClaimHandlerTest {
    @testSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user1', profile);
        insert user;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;

        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.HOT_IsFreelanceInterpreter__c = true;
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(resource);
        wageClaim.WorkType__c = workType.Id;
        insert wageClaim;
    }

    @IsTest
    static void retractChildWageClaims_onAfterUpdate() {
        HOT_WageClaim__c parentWageClaim = [SELECT Id, Status__c FROM HOT_WageClaim__c LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource];

        HOT_WageClaim__c childWageClaim = HOT_TestDataFactory.createWageClaim(resource);
        childWageClaim.ParentWageClaim__c = parentWageClaim.Id;
        insert childWageClaim;

        parentWageClaim.Status__c = 'Retracted Availability';

        Test.startTest();
        update parentWageClaim;
        Test.stopTest();

        childWageClaim = [SELECT Id, Status__c FROM HOT_WageClaim__c WHERE Id = :childWageClaim.Id LIMIT 1];

        System.assertEquals('Retracted Availability', childWageClaim.Status__c, 'Could not retract child wage claims');
    }

    @IsTest
    static void setFieldsBasedOnParentTest_onAfterInsert() {
        HOT_WageClaim__c parentWageClaim = [SELECT Id, WorkType__c FROM HOT_WageClaim__c LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource];
        HOT_WageClaim__c childWageClaim = HOT_TestDataFactory.createWageClaim(resource);
        childWageClaim.ParentWageClaim__c = parentWageClaim.Id;

        Test.startTest();
        insert childWageClaim;
        Test.stopTest();

        childWageClaim = [SELECT Id, WorkType__c FROM HOT_WageClaim__c WHERE Id = :childWageClaim.Id LIMIT 1];

        System.assertEquals(
            parentWageClaim.WorkType__c,
            childWageClaim.WorkType__c,
            'Could not set fields on child wage claim based on parent wage claim'
        );
    }
    @IsTest
    static void setServiceTerritoryBasedOnServiceResource_OnBeforeInsert() {
        ServiceResource resource = [SELECT Id, HOT_ServiceTerritory__c FROM ServiceResource];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(resource);

        Test.startTest();
        insert wageClaim;
        Test.stopTest();

        wageClaim = [SELECT Id, ServiceTerritory__c FROM HOT_WageClaim__c LIMIT 1];

        System.assertEquals(
            resource.HOT_ServiceTerritory__c,
            wageClaim.ServiceTerritory__c,
            'Service Territory was not set correctly'
        );
    }
}
