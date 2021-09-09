@isTest
private class HOT_WageClaimServiceTest {
    @testSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user1', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.HOT_IsFreelanceInterpreter__c = true;
        insert resource;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointmentId,
            serviceResourceId
        );
        insert assignedResource;
        delete assignedResource;
    }

    @isTest
    static void assignTest() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        delete assignedResource;

        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];

        Test.startTest();
        HOT_WageClaimService.assign(wageClaim.Id, assignedResource.serviceAppointmentId);
        Test.stopTest();

        List<AssignedResource> assignedResources = [
            SELECT Id
            FROM AssignedResource
            WHERE
                ServiceAppointmentId = :assignedResource.ServiceAppointmentId
                AND ServiceResourceId = :wageClaim.ServiceResource__c
        ];
        System.assertEquals(
            1,
            assignedResources.size(),
            'Could not assign resource to service appointment from Wage Claim'
        );
    }

    @isTest
    static void getServiceAppointmentsTest() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        delete assignedResource;

        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        List<ServiceAppointment> serviceAppointments = HOT_WageClaimService.getServiceAppointments(wageClaim.Id);

        System.assertEquals(
            1,
            serviceAppointments.size(),
            'Could not get Service Appointments overlapping with Wage Claim'
        );
    }

    @isTest
    static void updateWageClaimsFutureTest() {
    }
}
