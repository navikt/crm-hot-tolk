@IsTest
private class HOT_TjenesteleverandorListControllerTest {
    private static final String TEST_USERNAME =
        'tjenesteleverandor-list-' +
        UserInfo.getOrganizationId() +
        '@test.nav.no';

    @TestSetup
    static void createAppointments() {
        createTestUser();

        WorkType workType = HOT_TestDataFactory.createWorkType('supplier list');
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('supplier list', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer index = 0; index < 2; index++) {
            ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            appointments.add(appointment);
        }
        insert appointments;
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = 'None';
            appointment.HOT_IsReleasedToTjenesteleverandor__c = true;
            appointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        }
        update appointments;

        appointments[1].HOT_TjenesteleverandorStatus__c = 'Accepted';
        update appointments[1];
    }

    private static void createTestUser() {
        // USER_MODE keeps the running user's original FLS context in CI, so execute as a newly permissioned user.
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = HOT_TestDataFactory.createUser('TLList', profile);
        testUser.Username = TEST_USERNAME;
        testUser.Alias = 'tllist';
        testUser.CommunityNickname = 'tllist' + UserInfo.getOrganizationId();
        testUser.LanguageLocaleKey = 'en_US';
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Admin' LIMIT 1];

        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUser;
            insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permissionSet.Id);
        }
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Username = :TEST_USERNAME LIMIT 1];
    }

    private static List<ServiceAppointment> getTransferredAppointmentsAsTestUser() {
        List<ServiceAppointment> appointments;
        System.runAs(getTestUser()) {
            appointments = HOT_TjenesteleverandorListController.getTransferredServiceAppointments();
        }
        return appointments;
    }

    private static List<ServiceAppointment> getAcceptedAppointmentsAsTestUser() {
        List<ServiceAppointment> appointments;
        System.runAs(getTestUser()) {
            appointments = HOT_TjenesteleverandorListController.getAcceptedServiceAppointments();
        }
        return appointments;
    }

    @IsTest
    static void returnsTransferredAppointmentsCount() {
        Integer count;
        System.runAs(getTestUser()) {
            System.Test.startTest();
            count = HOT_TjenesteleverandorListController.getTransferredServiceAppointmentsCount();
            System.Test.stopTest();
        }

        Assert.areEqual(1, count, 'Only the transferred appointment should be counted');
    }

    @IsTest
    static void excludesReleasedAppointmentsFromTransferredListAndCount() {
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);
        WorkOrderLineItem workOrderLineItem = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        ServiceAppointment transferredAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        transferredAppointment.Status = 'Released to Freelance';
        transferredAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        transferredAppointment.HOT_IsReleasedToTjenesteleverandor__c = true;
        transferredAppointment.HOT_IsReleasedToFreelance__c = true;
        insert transferredAppointment;

        System.runAs(getTestUser()) {
            System.Test.startTest();
            Assert.areEqual(1, HOT_TjenesteleverandorListController.getTransferredServiceAppointmentsCount());
            Assert.areEqual(1, HOT_TjenesteleverandorListController.getTransferredServiceAppointments().size());
            System.Test.stopTest();
        }
    }

    @IsTest
    static void returnsOnlyTransferredAppointments() {
        System.Test.startTest();
        List<ServiceAppointment> appointments = getTransferredAppointmentsAsTestUser();
        System.Test.stopTest();

        Assert.areEqual(1, appointments.size(), 'Only the transferred appointment should be returned');
        Assert.areEqual(
            'Transferred',
            appointments[0].HOT_TjenesteleverandorStatus__c,
            'The transferred list should contain transferred appointments'
        );
        Assert.isNotNull(
            appointments[0].HOT_TjenesteleverandorDeadline__c,
            'The transferred list should include the supplier response deadline'
        );
        Assert.areEqual(
            false,
            appointments[0].HOT_IsOtherEconomicProvicer__c,
            'The list should expose the Service Appointment formula without request-owner data'
        );
        Assert.isNotNull(
            appointments[0].AppointmentNumber,
            'The list should use the standard appointment number instead of its duplicate formula'
        );
    }

    @IsTest
    static void returnsOnlyAcceptedSA() {
        System.Test.startTest();
        List<ServiceAppointment> appointments = getAcceptedAppointmentsAsTestUser();
        System.Test.stopTest();

        Assert.areEqual(1, appointments.size(), 'Only the accepted appointment should be returned');
        Assert.areEqual(
            'Accepted',
            appointments[0].HOT_TjenesteleverandorStatus__c,
            'The accepted list should contain accepted appointments'
        );
        Assert.isNotNull(
            appointments[0].HOT_TjenesteleverandorAcceptDate__c,
            'The accepted list should include the acceptance time'
        );
        Assert.areEqual(
            false,
            appointments[0].HOT_IsOtherEconomicProvicer__c,
            'The list should expose the Service Appointment formula without request-owner data'
        );
        Assert.isNotNull(
            appointments[0].AppointmentNumber,
            'The list should use the standard appointment number instead of its duplicate formula'
        );
    }

    @IsTest
    static void returnsSAWithReleasedStatus() {
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);
        WorkOrderLineItem workOrderLineItem = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        ServiceAppointment acceptedAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        acceptedAppointment.Status = 'Released to Freelance';
        acceptedAppointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        acceptedAppointment.HOT_IsReleasedToTjenesteleverandor__c = true;
        acceptedAppointment.HOT_IsReleasedToFreelance__c = true;
        insert acceptedAppointment;

        List<ServiceAppointment> appointments;
        System.runAs(getTestUser()) {
            System.Test.startTest();
            appointments = HOT_TjenesteleverandorListController.getReleasedServiceAppointments();
            System.Test.stopTest();
        }

        Assert.areEqual(1, appointments.size(), 'Only accepted appointments released to freelance should be returned');
        for (ServiceAppointment appointment : appointments) {
            Assert.areEqual(
                'Accepted',
                appointment.HOT_TjenesteleverandorStatus__c,
                'The released list should exclude transferred appointments'
            );
            Assert.areEqual(
                'Released to Freelance',
                appointment.Status,
                'The released list should contain only SA status Released to Freelance'
            );
        }
    }

    private static List<ServiceAppointment> prepareReleaseAppointments() {
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);
        List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment LIMIT 2];
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = 'None';
            appointment.HOT_IsReleasedToTjenesteleverandor__c = true;
            appointment.HOT_DeadlineDate__c = Date.today().addDays(1);
            appointment.HOT_FreelanceSubject__c = 'Release test';
        }
        update appointments;
        List<ServiceAppointment> acceptedAppointments = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            acceptedAppointments.add(
                new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted')
            );
        }
        update acceptedAppointments;
        for (ServiceAppointment appointment : [
            SELECT Status, HOT_TjenesteleverandorStatus__c, HOT_IsReleasedToTjenesteleverandor__c
            FROM ServiceAppointment
        ]) {
            Assert.areEqual('None', appointment.Status);
            Assert.areEqual('Accepted', appointment.HOT_TjenesteleverandorStatus__c);
            Assert.isTrue(appointment.HOT_IsReleasedToTjenesteleverandor__c);
        }
        return appointments;
    }

    @IsTest
    static void releasesSelectedAppointmentsTogether() {
        List<ServiceAppointment> appointments = prepareReleaseAppointments();
        myTriggers.enable(HOT_ServiceAppointmentHandler.class);
        for (ServiceAppointment appointment : appointments) {
            appointment.HOT_FreelanceSubject__c = 'Updated release subject';
            appointment.HOT_DeadlineDate__c = Date.today().addDays(2);
        }
        System.runAs(getTestUser()) {
            Type testStubType = Type.forName('FSL_TestStub');
            if (testStubType != null) {
                Callable testStub = (Callable) testStubType.newInstance();
                testStub.call(
                    'addStatusTransition',
                    new Map<String, Object>{ 'fromStatus' => 'None', 'toStatus' => 'Released to Freelance' }
                );
            }
            System.Test.startTest();
            HOT_TjenesteleverandorReleaseService.releaseServiceAppointments(appointments);
            System.Test.stopTest();
        }
        for (ServiceAppointment appointment : [
            SELECT Id, Status, HOT_DeadlineDate__c, HOT_FreelanceSubject__c
            FROM ServiceAppointment
            WHERE Id IN :appointments
        ]) {
            Assert.areEqual('Released to Freelance', appointment.Status, 'Selected appointment: ' + appointment.Id);
            Assert.areEqual(Date.today().addDays(2), appointment.HOT_DeadlineDate__c);
            Assert.areEqual('Updated release subject', appointment.HOT_FreelanceSubject__c);
        }
    }

    @IsTest
    static void rejectsEntireReleaseWhenAnAppointmentIsNoLongerEligible() {
        List<ServiceAppointment> appointments = prepareReleaseAppointments();
        update new ServiceAppointment(Id = appointments[1].Id, Status = 'Scheduled');
        System.runAs(getTestUser()) {
            System.Test.startTest();
            try {
                HOT_TjenesteleverandorReleaseService.releaseServiceAppointments(appointments);
                Assert.fail('A changed appointment must prevent the entire release');
            } catch (AuraHandledException expected) {
                Assert.isNotNull(expected);
            }
            System.Test.stopTest();
        }
        Assert.areEqual(0, [SELECT COUNT() FROM ServiceAppointment WHERE Status = 'Released to Freelance']);
    }

    @IsTest
    static void rejectsReleaseWithMissingRequiredFields() {
        List<ServiceAppointment> appointments = prepareReleaseAppointments();
        appointments[1].HOT_DeadlineDate__c = null;
        System.runAs(getTestUser()) {
            System.Test.startTest();
            try {
                HOT_TjenesteleverandorReleaseService.releaseServiceAppointments(appointments);
                Assert.fail('Every appointment must have a deadline');
            } catch (AuraHandledException expected) {
                Assert.isNotNull(expected);
            }
            System.Test.stopTest();
        }
        Assert.areEqual(0, [SELECT COUNT() FROM ServiceAppointment WHERE Status = 'Released to Freelance']);
    }

    @IsTest
    static void returnsOnlyFinishedAcceptedSA() {
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);

        WorkOrderLineItem workOrderLineItem = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        List<ServiceAppointment> finishedAppointments = new List<ServiceAppointment>();
        Set<String> finishedStatuses = new Set<String>{ 'Completed', 'Cannot Complete', 'Canceled', 'Annul' };
        for (String appointmentStatus : finishedStatuses) {
            ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            appointment.Status = appointmentStatus;
            appointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
            appointment.HOT_IsReleasedToTjenesteleverandor__c = true;
            appointment.HOT_IsReleasedToFreelance__c = true;
            finishedAppointments.add(appointment);
        }
        insert finishedAppointments;

        ServiceAppointment transferredAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        transferredAppointment.Status = 'Completed';
        transferredAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        transferredAppointment.HOT_IsReleasedToTjenesteleverandor__c = true;
        transferredAppointment.HOT_IsReleasedToFreelance__c = true;
        insert transferredAppointment;

        Set<Id> expectedIds = new Map<Id, ServiceAppointment>(finishedAppointments).keySet();
        List<ServiceAppointment> appointments;
        System.runAs(getTestUser()) {
            System.Test.startTest();
            appointments = HOT_TjenesteleverandorListController.getFinishedServiceAppointments();
            System.Test.stopTest();
        }

        Assert.areEqual(4, appointments.size(), 'All four finished statuses should be returned');
        Assert.areEqual(
            expectedIds,
            new Map<Id, ServiceAppointment>(appointments).keySet(),
            'Exclude transferred appointments and accepted appointments that are still active'
        );
        for (ServiceAppointment appointment : appointments) {
            Assert.areEqual('Accepted', appointment.HOT_TjenesteleverandorStatus__c);
            Assert.isNotNull(appointment.AppointmentNumber);
        }
    }
}
