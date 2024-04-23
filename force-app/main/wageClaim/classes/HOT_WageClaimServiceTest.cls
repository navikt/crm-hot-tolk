@IsTest
private class HOT_WageClaimServiceTest {
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
    static void getServiceAppointmentsTest() {
        Test.startTest();
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        List<ServiceAppointment> serviceAppointments = HOT_WageClaimService.getServiceAppointments(wageClaim.Id);
        Test.stopTest();
        System.assertEquals(
            1,
            serviceAppointments.size(),
            'Could not get Service Appointments overlapping with Wage Claim'
        );
    }

    @IsTest
    static void SAWithARTimesChanged() {
        Test.startTest();
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
            LIMIT 1
        ];
        serviceAppointment.ActualStartTime = serviceAppointment.SchedStartTime.addMinutes(15);
        serviceAppointment.ActualEndTime = serviceAppointment.SchedEndTime.addMinutes(-15);
        serviceAppointment.Status = 'Completed';

        Test.stopTest();
        update serviceAppointment;

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, StartTime__c, EndTime__c FROM HOT_WageClaim__c];
        Boolean isWageClaimTimesCorrect, isWageClaimTimesCorrect2 = false;
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            if (
                wageClaim.StartTime__c == serviceAppointment.SchedStartTime &&
                wageClaim.EndTime__c == serviceAppointment.ActualStartTime
            ) {
                isWageClaimTimesCorrect = true;
            }
            if (
                wageClaim.StartTime__c == serviceAppointment.ActualEndTime &&
                wageClaim.EndTime__c == serviceAppointment.SchedEndTime
            ) {
                isWageClaimTimesCorrect2 = true;
            }
        }

        System.assertEquals(
            true,
            isWageClaimTimesCorrect && isWageClaimTimesCorrect2,
            'WageClaim start and end times were not set correctly.'
        );
        System.assertEquals(2, wageClaims.size(), 'Could not create WageClaim when actual time on SA was updated.');
    }

    @IsTest
    static void SAWithARTimesChangedAndIsAgreement() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceResource(Id = assignedResource.ServiceResourceId, HOT_AgreementFreelance__c = true);
        Test.startTest();
        HOT_Request__c request = [SELECT Id, ServiceResourceWithAgreement1__c FROM HOT_Request__c];
        request.ServiceResourceWithAgreement1__c = assignedResource.ServiceResourceId;
        update request;
        Test.stopTest();
        ServiceAppointment serviceAppointment = [
            SELECT
                Id,
                SchedStartTime,
                SchedEndTime,
                ActualStartTime,
                ActualEndTime,
                HOT_ServiceResource__c,
                HOT_Request__r.ServiceResourceWithAgreement1__c
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
            LIMIT 1
        ];
        serviceAppointment.ActualStartTime = serviceAppointment.SchedStartTime.addMinutes(15);
        serviceAppointment.ActualEndTime = serviceAppointment.SchedEndTime.addMinutes(-15);
        serviceAppointment.Status = 'Completed';

        update serviceAppointment;

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, StartTime__c, EndTime__c, ServiceResource__c
            FROM HOT_WageClaim__c
            WHERE ServiceResource__c = :serviceAppointment.HOT_ServiceResource__c
        ];
        System.assertEquals(0, wageClaims.size(), 'Wage Claim was incorrectly created when SR is on agreement.');
    }
}
