@isTest
private class HOT_UpdateWageClaimTest {
    @testSetup
    static void setup() {
        Integer numberOfWorkOrders = 3;

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

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < numberOfWorkOrders; i++) {
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.StartDate = request.StartTime__c.addHours(i);
            workOrder.EndDate = workOrder.StartDate.addHours(1);
            workOrders.add(workOrder);
        }
        insert workOrders;
        request.Status__c = 'Godkjent';
        update request;

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        for (ServiceAppointment serviceAppointment : [SELECT Id FROM ServiceAppointment]) {
            assignedResources.add(HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, resource.Id));
        }
        insert assignedResources;
    }

    @isTest
    static void updateWageClaimsFutureTest_CompletelyCovered() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointment.SchedStartTime;
        wageClaim.EndTime__c = serviceAppointment.SchedEndTime;
        insert wageClaim;

        Test.startTest();
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, Status__c FROM HOT_WageClaim__c];
        System.assertEquals(1, wageClaims.size(), 'Could not set WageClaim.Status = \'Covered\', complete cover');
        System.assertEquals(
            'Covered',
            wageClaims[0].Status__c,
            'Could not set WageClaim.Status = \'Covered\', complete cover'
        );
    }
    @isTest
    static void updateWageClaimsFutureTest_PartiallyCovered_split() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointment.SchedStartTime.addHours(-1);
        wageClaim.EndTime__c = serviceAppointment.SchedEndTime.addHours(1);
        insert wageClaim;

        Test.startTest();
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
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
        System.assertEquals(
            'Covered',
            updatedWageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', split cover'
        );
        System.assertEquals(
            serviceAppointment.SchedStartTime,
            updatedWageClaim.StartTime__c,
            'Could not set correct Start Time for original WageClaim'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
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
            serviceAppointment.SchedStartTime,
            newWageClaims[0].EndTime__c,
            'Could not set correct End Time for new WageClaim1'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
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
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointment.SchedStartTime.addMinutes(30);
        wageClaim.EndTime__c = serviceAppointment.SchedEndTime.addMinutes(30);
        insert wageClaim;

        Test.startTest();
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
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
        System.assertEquals(
            'Covered',
            updatedWageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', lower cover'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            updatedWageClaim.EndTime__c,
            'Could not set correct End Time for original WageClaim'
        );

        System.assertEquals(1, newWageClaims.size(), 'Could not create updated Wage Claim');

        System.assertEquals(
            serviceAppointment.SchedEndTime,
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
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointment.SchedStartTime.addMinutes(-30);
        wageClaim.EndTime__c = serviceAppointment.SchedEndTime.addMinutes(-30);
        insert wageClaim;

        Test.startTest();
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
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
        System.assertEquals(
            'Covered',
            updatedWageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', upper cover'
        );
        System.assertEquals(
            serviceAppointment.SchedStartTime,
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
            serviceAppointment.SchedStartTime,
            newWageClaims[0].EndTime__c,
            'Could not set correct End Time for new WageClaim'
        );
    }

    @isTest
    static void updateWageClaimsFutureTest_CompletelyCovered_arChanged() {
        AssignedResource assignedResource = [
            SELECT Id, ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            LIMIT 1
        ];
        Id oldServiceResourceId = assignedResource.ServiceResourceId;

        ServiceResource serviceResource2 = [SELECT Id FROM ServiceResource WHERE Id != :oldServiceResourceId LIMIT 1];

        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
            LIMIT 1
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource2);
        wageClaim.StartTime__c = serviceAppointment.SchedStartTime;
        wageClaim.EndTime__c = serviceAppointment.SchedEndTime;
        insert wageClaim;

        assignedResource.ServiceResourceId = serviceResource2.Id;

        Test.startTest();
        update assignedResource;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        Test.stopTest();

        wageClaim = [
            SELECT Id, Status__c
            FROM HOT_WageClaim__c
            WHERE ServiceResource__c = :serviceResource2.Id
            LIMIT 1
        ];
        System.assertEquals(
            'Covered',
            wageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', complete cover when AR changed'
        );
    }

    // Multiple SA Assigned at the same time

    @isTest
    static void updateWageClaimsFutureTest_ConnectedSA() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 2
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointments[0].SchedStartTime;
        wageClaim.EndTime__c = serviceAppointments[1].SchedEndTime;
        insert wageClaim;

        Test.startTest();
        serviceAppointments[0].Status = 'Dispatched';
        serviceAppointments[1].Status = 'Dispatched';
        update serviceAppointments;

        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, Status__c, StartTime__c, EndTime__c FROM HOT_WageClaim__c];
        System.assertEquals(2, wageClaims.size(), 'Could not update wageClaim with multiple SA updates');
        List<HOT_WageClaim__c> updatedWageClaims = [
            SELECT Id, Status__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Status__c = 'Covered'
        ];
        System.assertEquals(2, wageClaims.size(), 'Could not update wageClaim with multiple SA updates');
    }

    @isTest
    static void updateWageClaimsFutureTest_SpaceBetweenSA() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 3
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointments[0].SchedStartTime;
        wageClaim.EndTime__c = serviceAppointments[2].SchedEndTime;
        insert wageClaim;

        Test.startTest();
        serviceAppointments[0].Status = 'Dispatched';
        serviceAppointments[2].Status = 'Dispatched';
        update serviceAppointments;

        Test.stopTest();

        List<HOT_WageClaim__c> updatedWageClaims = [
            SELECT Id, Status__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Status__c = 'Covered'
        ];
        System.assertEquals(2, updatedWageClaims.size(), 'Wage Claims were updated');
        List<HOT_WageClaim__c> wageClaims = [SELECT Id, Status__c, StartTime__c, EndTime__c FROM HOT_WageClaim__c];
        System.assertEquals(3, wageClaims.size(), 'Could not update wageClaim with multiple SA updates');
    }

    @isTest
    static void updateWageClaimsFutureTest_SpaceAroundSA() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 3
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointments[0].SchedStartTime.addHours(-1);
        wageClaim.EndTime__c = serviceAppointments[2].SchedEndTime.addHours(1);
        insert wageClaim;

        Test.startTest();
        serviceAppointments[0].Status = 'Dispatched';
        serviceAppointments[2].Status = 'Dispatched';
        update serviceAppointments;

        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, Status__c, StartTime__c, EndTime__c, ParentWageClaim__c
            FROM HOT_WageClaim__c
        ];
        System.assertEquals(5, wageClaims.size(), 'Could not update wageClaim with multiple SA updates');
        wageClaims = [SELECT Id, Status__c, StartTime__c, EndTime__c FROM HOT_WageClaim__c WHERE Status__c = 'Covered'];
        System.assertEquals(2, wageClaims.size(), 'Could not update wageClaim with multiple SA updates');
    }

    @isTest
    static void updateWageClaimsFutureTest_TimeChanged() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.StartTime__c = serviceAppointment.SchedStartTime.addHours(1);
        wageClaim.EndTime__c = serviceAppointment.SchedEndTime.addHours(1);
        insert wageClaim;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        Test.startTest();
        List<HOT_WageClaim__c> wageClaimsBefore = [SELECT Id, Status__c FROM HOT_WageClaim__c];

        serviceAppointment.SchedStartTime = serviceAppointment.SchedStartTime.addHours(1);
        serviceAppointment.SchedEndTime = serviceAppointment.SchedEndTime.addHours(1);
        update serviceAppointment;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaimsAfter = [SELECT Id, Status__c FROM HOT_WageClaim__c];
        System.assertEquals(1, wageClaimsBefore.size(), 'Not correct number of Wage Claims');
        System.assertEquals(1, wageClaimsAfter.size(), 'Not correct number of Wage Claims');
        System.assertEquals('Open', wageClaimsBefore[0].Status__c, 'Should be Open before time is changed');
        System.assertEquals('Covered', wageClaimsAfter[0].Status__c, 'Should be Covered after time is changed');
    }
}
