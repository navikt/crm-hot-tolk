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

    @isTest
    static void createWageClaimTest_saStatusNone() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when SA Status None');
    }
    @isTest
    static void createWageClaimTest_saStatusCanceled() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Canceled');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when SA Status Canceled');
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
        System.assertEquals(
            'Covered',
            wageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', complete cover'
        );
    }
    @isTest
    static void updateWageClaimsFutureTest_PartiallyCovered_split() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
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
        System.assertEquals(
            'Covered',
            updatedWageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', split cover'
        );
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
        System.assertEquals(
            'Covered',
            updatedWageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', lower cover'
        );
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
        System.assertEquals(
            'Covered',
            updatedWageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', upper cover'
        );
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
        System.assertEquals(
            'Covered',
            wageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', code coverage'
        );
    }

    @isTest
    static void assignTest() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        delete assignedResource;
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

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

    @isTest
    static void dontCreateWageClaimIfAgreement() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceResource(Id = assignedResource.ServiceResourceId, HOT_AgreementFreelance__c = true);
        HOT_Request__c request = [SELECT Id, ServiceResourceWithAgreement1__c FROM HOT_Request__c];
        request.ServiceResourceWithAgreement1__c = assignedResource.ServiceResourceId;
        update request;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];

        System.assertEquals(0, wageClaims.size(), 'WageClaim was wrongly created for Agreement Interpreter');
    }

    @isTest
    static void createWageClaimTest_arDeleted() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        delete assignedResource;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when AR Deleted');
    }
    @isTest
    static void createWageClaimTest_arChanged() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        Id oldServiceResourceId = assignedResource.ServiceResourceId;

        ServiceResource serviceResource2 = [SELECT Id FROM ServiceResource WHERE Id != :oldServiceResourceId LIMIT 1];

        assignedResource.ServiceResourceId = serviceResource2.Id;

        Test.startTest();
        update assignedResource;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceResource__c
            FROM HOT_WageClaim__c
            WHERE ServiceResource__c = :oldServiceResourceId
            LIMIT 1
        ];
        System.assertEquals(1, wageClaims.size(), 'Could not create Wage Claims when AR Changed');
    }

    @isTest
    static void updateWageClaimsFutureTest_CompletelyCovered_arChanged() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
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
        Test.stopTest();

        wageClaim = [SELECT Id, Status__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(
            'Covered',
            wageClaim.Status__c,
            'Could not set WageClaim.Status = \'Covered\', complete cover when AR changed'
        );
    }

    @isTest
    static void createWageClaimTest_negative_Completed() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'Completed');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(0, wageClaims.size(), 'Wrongly created Wage Claims');
    }

    @isTest
    static void createWageClaimTest_negative_duplicates() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        delete assignedResource;

        Test.startTest();
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        System.assertEquals(1, wageClaims.size(), 'Wrongly created Wage Claims');
    }

    @isTest
    static void updateWageClaimsFutureTest_MultipleSA() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');

        HOT_WageClaim__c wageClaim = [SELECT Id, StartTime__c, EndTime__c FROM HOT_WageClaim__c LIMIT 1];
        wageClaim.EndTime__c = wageClaim.EndTime__c.addHours(2);
        update wageClaim;

        ServiceAppointment serviceAppointment = [
            SELECT Id, Status, ParentRecordId
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
        ];
        ServiceAppointment newServiceAppointment = serviceAppointment.clone(false, true, false, false);
        newServiceAppointment.SchedStartTime = wageClaim.EndTime__c.addHours(-1);
        newServiceAppointment.SchedEndTime = wageClaim.EndTime__c;
        newServiceAppointment.EarliestStartTime = newServiceAppointment.SchedStartTime;
        newServiceAppointment.DueDate = newServiceAppointment.SchedEndTime;
        insert newServiceAppointment;

        Test.startTest();
        insert new AssignedResource(
            ServiceAppointmentId = newServiceAppointment.Id,
            ServiceResourceId = assignedResource.ServiceResourceId
        );

        serviceAppointment.Status = 'Dispatched';
        newServiceAppointment.Status = 'Dispatched';
        update new List<ServiceAppointment>{ serviceAppointment, newServiceAppointment };
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, Status__c, StartTime__c, EndTime__c FROM HOT_WageClaim__c];
        System.assertEquals(3, wageClaims.size(), 'Could not update wageClaim with multiple SA updates');
    }

    @isTest
    static void SAWithARTimesChanged() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
            LIMIT 1
        ];
        serviceAppointment.ActualStartTime = DateTime.now().addHours(1).addMinutes(30);
        serviceAppointment.ActualEndTime = DateTime.now().addHours(1).addMinutes(30);
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [SELECT Id FROM HOT_WageClaim__c];
        System.assertEquals(2, wageClaims.size(), 'Could not create WageClaim when actual time on SA was updated.');
    }
}
