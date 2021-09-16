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
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointmentId,
            serviceResourceId
        );
        insert assignedResource;
        update new ServiceAppointment(Id = serviceAppointmentId, Status = 'Dispatched');
    }

    @isTest
    static void createWageClaimTest_saStatusNone() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims');
    }
    @isTest
    static void createWageClaimTest_saStatusCanceled() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Canceled');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims');
    }

    @isTest
    static void createWageClaimTest_negative() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Completed');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(0, wageClaims.size(), 'Could not create Wage Claims');
    }

    @isTest
    static void updateWageClaimsFutureTest_CompletelyCovered() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        AssignedResource newAssignedResource = HOT_TestDataFactory.createAssignedResource(
            assignedResource.ServiceAppointmentId,
            assignedResource.ServiceResourceId
        );
        update new ServiceAppointment(Id = newAssignedResource.ServiceAppointmentId, Status = 'None');

        Test.startTest();
        update new ServiceAppointment(Id = newAssignedResource.ServiceAppointmentId, Status = 'Dispatched');
        Test.stopTest();

        HOT_WageClaim__c wageClaim = [SELECT Id, Status__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals('Covered', wageClaim.Status__c, 'Could not set WageClaim.Status = \'Covered\'');
    }
    @isTest
    static void updateWageClaimsFutureTest_PartiallyCovered_split() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        delete assignedResource;
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        HOT_WageClaim__c wageClaim = [SELECT Id, StartTime__c, EndTime__c FROM HOT_WageClaim__c LIMIT 1];
        Datetime saStartTime = wageClaim.StartTime__c;
        Datetime saEndTime = wageClaim.EndTime__c;
        wageClaim.StartTime__c = wageClaim.StartTime__c.addMinutes(-10);
        wageClaim.EndTime__c = wageClaim.EndTime__c.addMinutes(10);
        update wageClaim;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Dispatched');
        Test.stopTest();

        HOT_WageClaim__c updatedWageClaim = [
            SELECT Id, Status__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaim.Id
        ];
        List<HOT_WageClaim__c> newWageClaims = [
            SELECT Id, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id != :wageClaim.Id
            ORDER BY StartTime__c ASC
        ];
        System.assertEquals('Covered', updatedWageClaim.Status__c, 'Could not set WageClaim.Status = \'Covered\'');
        System.assertEquals(
            saStartTime,
            updatedWageClaim.StartTime__c,
            'Could not set correct Start Time for original WageClaim'
        );
        System.assertEquals(
            saEndTime,
            updatedWageClaim.EndTime__c,
            'Could not set correct End Time for original WageClaim'
        );

        System.assertEquals(2, newWageClaims.size(), 'Could not split Wage Claim');

        System.assertEquals(
            wageClaim.StartTime__c,
            newWageClaims[0].StartTime__c,
            'Could not set correct Start Time for new WageClaim1'
        );
        System.assertEquals(
            saStartTime,
            newWageClaims[0].EndTime__c,
            'Could not set correct End Time for new WageClaim1'
        );
        System.assertEquals(
            saEndTime,
            newWageClaims[1].StartTime__c,
            'Could not set correct Start Time for new WageClaim2'
        );
        System.assertEquals(
            wageClaim.EndTime__c,
            newWageClaims[1].EndTime__c,
            'Could not set correct End Time for new WageClaim2'
        );
    }
    @isTest
    static void updateWageClaimsFutureTest_PartiallyCovered_lower() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        HOT_WageClaim__c wageClaim = [SELECT Id, StartTime__c, EndTime__c FROM HOT_WageClaim__c LIMIT 1];
        Datetime saStartTime = wageClaim.StartTime__c;
        Datetime saEndTime = wageClaim.EndTime__c;
        wageClaim.StartTime__c = wageClaim.StartTime__c.addMinutes(10);
        wageClaim.EndTime__c = wageClaim.EndTime__c.addMinutes(10);
        update wageClaim;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Dispatched');
        Test.stopTest();

        HOT_WageClaim__c updatedWageClaim = [
            SELECT Id, Status__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaim.Id
        ];
        List<HOT_WageClaim__c> newWageClaims = [
            SELECT Id, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id != :wageClaim.Id
            ORDER BY StartTime__c ASC
        ];
        System.assertEquals('Covered', updatedWageClaim.Status__c, 'Could not set WageClaim.Status = \'Covered\'');
        System.assertEquals(
            saEndTime,
            updatedWageClaim.EndTime__c,
            'Could not set correct End Time for original WageClaim'
        );

        System.assertEquals(1, newWageClaims.size(), 'Could not create updated Wage Claim');

        System.assertEquals(
            saEndTime,
            newWageClaims[0].StartTime__c,
            'Could not set correct Start Time for new WageClaim'
        );
        System.assertEquals(
            wageClaim.EndTime__c,
            newWageClaims[0].EndTime__c,
            'Could not set correct End Time for new WageClaim'
        );
    }
    @isTest
    static void updateWageClaimsFutureTest_PartiallyCovered_upper() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        HOT_WageClaim__c wageClaim = [SELECT Id, StartTime__c, EndTime__c FROM HOT_WageClaim__c LIMIT 1];
        Datetime saStartTime = wageClaim.StartTime__c;
        Datetime saEndTime = wageClaim.EndTime__c;
        wageClaim.StartTime__c = wageClaim.StartTime__c.addMinutes(-10);
        wageClaim.EndTime__c = wageClaim.EndTime__c.addMinutes(-10);
        update wageClaim;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Dispatched');
        Test.stopTest();

        HOT_WageClaim__c updatedWageClaim = [
            SELECT Id, Status__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaim.Id
        ];
        List<HOT_WageClaim__c> newWageClaims = [
            SELECT Id, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id != :wageClaim.Id
            ORDER BY StartTime__c ASC
        ];
        System.assertEquals('Covered', updatedWageClaim.Status__c, 'Could not set WageClaim.Status = \'Covered\'');
        System.assertEquals(
            saStartTime,
            updatedWageClaim.StartTime__c,
            'Could not set correct Start Time for original WageClaim'
        );

        System.assertEquals(1, newWageClaims.size(), 'Could not create updated Wage Claim');

        System.assertEquals(
            wageClaim.StartTime__c,
            newWageClaims[0].StartTime__c,
            'Could not set correct Start Time for new WageClaim'
        );
        System.assertEquals(
            saStartTime,
            newWageClaims[0].EndTime__c,
            'Could not set correct End Time for new WageClaim'
        );
    }

    @isTest
    static void updateWageClaimsFutureTest_codeCov() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        HOT_WageClaim__c wageClaim = [
            SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            LIMIT 1
        ];
        HOT_WageClaim__c newWageClaim = wageClaim.clone(false, true, false, false);
        insert newWageClaim;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Dispatched');
        Test.stopTest();

        wageClaim = [SELECT Id, Status__c FROM HOT_WageClaim__c WHERE Id = :wageClaim.Id LIMIT 1];
        System.assertEquals('Covered', wageClaim.Status__c, 'Could not set WageClaim.Status = \'Covered\'');
    }

    //Overlapping Service Appointments
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
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        List<ServiceAppointment> serviceAppointments = HOT_WageClaimService.getServiceAppointments(wageClaim.Id);

        System.assertEquals(
            1,
            serviceAppointments.size(),
            'Could not get Service Appointments overlapping with Wage Claim'
        );
    }
}
