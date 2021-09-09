@isTest
private class HOT_SAWageClaimServiceTest {
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
    }

    @isTest
    static void testMethod1() {
        AssignedResource assignedResource = [SELECT Id FROM AssignedResource];
        delete assignedResource;

        List<HOT_WageClaim__c> wageClaims = [SELECT Id FROM HOT_WageClaim__c];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claim');
    }
}
