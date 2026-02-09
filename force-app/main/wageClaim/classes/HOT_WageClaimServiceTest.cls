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

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert assignedResource;

        sa.Status = 'Dispatched';
        update sa;
    }

    @IsTest
    static void getServiceAppointmentsTest() {
        Test.startTest();

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Datetime startDt = System.now().addHours(24);
        Datetime endDt = startDt.addHours(2);

        update new ServiceAppointment(Id = sa.Id, SchedStartTime = startDt, SchedEndTime = endDt);

        update new ServiceAppointment(Id = sa.Id, Status = 'None');

        HOT_WageClaim__c wageClaim = [SELECT Id FROM HOT_WageClaim__c LIMIT 1];
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
        ServiceAppointment sa = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment LIMIT 1];
        Datetime startDt = System.now().addHours(24);
        Datetime endDt = startDt.addHours(2);

        update new ServiceAppointment(Id = sa.Id, SchedStartTime = startDt, SchedEndTime = endDt);

        Test.startTest();

        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :sa.Id
            LIMIT 1
        ];

        Datetime newStartTime = serviceAppointment.SchedStartTime.addMinutes(15);
        Datetime newEndTime = serviceAppointment.SchedEndTime.addMinutes(-15);

        serviceAppointment.SchedStartTime = newStartTime;
        serviceAppointment.SchedEndTime = newEndTime;
        update serviceAppointment;

        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            ORDER BY StartTime__c
        ];

        System.assertEquals(
            2,
            wageClaims.size(),
            'Could not create 2 WageClaims when scheduled time on Dispatched SA was updated.'
        );

        System.assertEquals(
            startDt,
            wageClaims[0].StartTime__c,
            'First WageClaim start time should match old SchedStartTime'
        );
        System.assertEquals(
            newStartTime,
            wageClaims[0].EndTime__c,
            'First WageClaim end time should match new SchedStartTime'
        );
        System.assertEquals(
            newEndTime,
            wageClaims[1].StartTime__c,
            'Second WageClaim start time should match new SchedEndTime'
        );
        System.assertEquals(endDt, wageClaims[1].EndTime__c, 'Second WageClaim end time should match old SchedEndTime');
    }

    @IsTest
    static void SAWithARTimesChangedAndIsAgreement() {
        AssignedResource assignedResource = [
            SELECT ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            LIMIT 1
        ];

        update new ServiceResource(Id = assignedResource.ServiceResourceId, HOT_AgreementFreelance__c = true);

        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        request.ServiceResourceWithAgreement1__c = assignedResource.ServiceResourceId;
        update request;

        ServiceAppointment sa = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment LIMIT 1];
        Datetime startDt = System.now().addHours(24);
        Datetime endDt = startDt.addHours(2);

        update new ServiceAppointment(Id = sa.Id, SchedStartTime = startDt, SchedEndTime = endDt);

        Test.startTest();

        update new ServiceAppointment(Id = sa.Id, Status = 'None');

        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id FROM HOT_WageClaim__c];

        System.assertEquals(0, wageClaims.size(), 'Wage Claim should NOT be created when SR has agreement.');
    }

    @IsTest
    static void shouldNotCreateWageClaimWhenStartTimeIsMoreThan48HoursAway() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Datetime startDt = System.now().addHours(49);
        Datetime endDt = startDt.addHours(2);

        Test.startTest();

        update new ServiceAppointment(Id = sa.Id, SchedStartTime = startDt, SchedEndTime = endDt);

        Test.stopTest();

        Integer wageClaimCount = [SELECT COUNT() FROM HOT_WageClaim__c];
        System.assertEquals(
            0,
            wageClaimCount,
            'Wage Claim should NOT be created when Service Appointment starts more than 48 hours ahead.'
        );
    }
}
