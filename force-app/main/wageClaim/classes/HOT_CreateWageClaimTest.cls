@IsTest
private class HOT_CreateWageClaimTest {
    @testSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user1', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.HOT_IsFreelanceInterpreter__c = true;
        insert resource;

        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :user.Id LIMIT 1].Id;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointmentId,
            serviceResourceId
        );
        insert assignedResource;
        update new ServiceAppointment(Id = serviceAppointmentId, Status = 'Dispatched');
    }

    @IsTest
    static void createWageClaimTest_saStatusNone() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when SA Status None');
    }
    @IsTest
    static void createWageClaimTest_saStatusCanceled() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Canceled');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when SA Status Canceled');
    }

    @IsTest
    static void dontCreateWageClaimIfAgreement() {
        Test.startTest();
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceResource(Id = assignedResource.ServiceResourceId, HOT_AgreementFreelance__c = true);
        HOT_Request__c request = [SELECT Id, ServiceResourceWithAgreement1__c FROM HOT_Request__c];
        request.ServiceResourceWithAgreement1__c = assignedResource.ServiceResourceId;
        update request;

        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        Test.stopTest();
        System.assertEquals(0, wageClaims.size(), 'WageClaim was wrongly created for Agreement Interpreter');
    }

    @IsTest
    static void createWageClaimTest_arDeleted() {
        Test.startTest();

        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        delete assignedResource;

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        Test.stopTest();
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when AR Deleted');
    }
    @IsTest
    static void createWageClaimTest_arChanged() {
        Test.startTest();
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        Id oldServiceResourceId = assignedResource.ServiceResourceId;

        ServiceResource serviceResource2 = [SELECT Id FROM ServiceResource WHERE Id != :oldServiceResourceId LIMIT 1];

        assignedResource.ServiceResourceId = serviceResource2.Id;

        update assignedResource;

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceResource__c
            FROM HOT_WageClaim__c
            WHERE ServiceResource__c = :oldServiceResourceId
            LIMIT 1
        ];
        Test.stopTest();
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when AR Changed');
    }

    @IsTest
    static void createWageClaimTest_negative_Completed() {
        Test.startTest();
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Completed');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(0, wageClaims.size(), 'Wrongly created Wage Claims');
    }

    @IsTest
    static void createWageClaimTest_negative_duplicates() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        delete assignedResource;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        Test.stopTest();
        System.assertEquals(1, wageClaims.size(), 'Wrongly created Wage Claims');
    }

    private static Integer testTimeChange(Integer startOffsetInMinutes, Integer endOffsetInMinutes) {
        ServiceAppointment serviceAppointment = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment];
        Test.startTest();
        serviceAppointment.SchedStartTime = serviceAppointment.SchedStartTime.addMinutes(startOffsetInMinutes);
        serviceAppointment.SchedEndTime = serviceAppointment.SchedEndTime.addMinutes(endOffsetInMinutes);
        update serviceAppointment;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, StartTime__c, EndTime__c, Status__c
            FROM HOT_WageClaim__c
            LIMIT 5
        ];

        return wageClaims.size();
    }

    @isTest
    static void createWageClaimTest_timeChangesLower() {
        Integer wageClaimCount = testTimechange(-10, -10);
        System.assertEquals(1, wageClaimCount, 'Did not create Wage Claim as expected');
    }

    @isTest
    static void createWageClaimTest_timeChangesCovered() {
        Integer wageClaimCount = testTimeChange(-10, 10);
        System.assertEquals(0, wageClaimCount, 'Created Wage Claim when new timespan covers the old timespan of SA');
    }

    @isTest
    static void createWageClaimTest_timeChangesUpper() {
        Integer wageClaimCount = testTimeChange(10, 10);
        System.assertEquals(1, wageClaimCount, 'Did not create Wage Claim as expected');
    }

    @isTest
    static void createWageClaimTest_timeChangesExactlyAfter() {
        Integer wageClaimCount = testTimeChange(120, 120);
        System.assertEquals(1, wageClaimCount, 'Did not create Wage Claim as expected');
    }

    @isTest
    static void createWageClaimTest_timeChangesAfter() {
        Integer wageClaimCount = testTimeChange(400, 400);
        System.assertEquals(1, wageClaimCount, 'Did not create Wage Claim as expected');
    }
}
