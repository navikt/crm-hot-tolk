@IsTest
private class HOT_TjenesteleverandorAcceptServiceTest {
    private static final String TEST_USERNAME =
        'tjenesteleverandor-accept-' + UserInfo.getOrganizationId() + '@test.nav.no';

    @TestSetup
    static void createTestAppointments() {
        createTestUser();
        createTransferredAppointments(5, 'acceptance setup');
    }

    private static void createTestUser() {
        // USER_MODE keeps the running user's original FLS context in CI, so execute as a newly permissioned user.
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = HOT_TestDataFactory.createUser('TLAccept', profile);
        testUser.Username = TEST_USERNAME;
        testUser.Alias = 'tlaccept';
        testUser.CommunityNickname = 'tlaccept' + UserInfo.getOrganizationId();
        PermissionSet permissionSet = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'HOT_Admin'
            LIMIT 1
        ];

        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUser;
            insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permissionSet.Id);
        }
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Username = :TEST_USERNAME LIMIT 1];
    }

    private static List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> acceptAsTestUser(
        List<Id> serviceAppointmentIds
    ) {
        List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> results;
        System.runAs(getTestUser()) {
            results = HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments(serviceAppointmentIds);
        }
        return results;
    }

    @IsTest
    static void acceptsSingleTransferredAppointment() {
        ServiceAppointment appointment = getTransferredAppointments(1)[0];
        setAcceptancePermission(true);

        Test.startTest();
        List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> results = acceptAsTestUser(
            new List<Id>{ appointment.Id }
        );
        Test.stopTest();

        ServiceAppointment actual = getAppointment(appointment.Id);
        Assert.areEqual(1, results.size(), 'The service should return one result');
        Assert.isTrue(results[0].success, 'The transferred appointment should be accepted');
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c, 'Supplier status should be accepted');
        Assert.isNotNull(actual.HOT_TjenesteleverandorAcceptDate__c, 'Acceptance time should be stamped by Flow');
        Assert.isNull(actual.HOT_TjenesteleverandorDeadline__c, 'Acceptance should clear the supplier deadline');
    }

    @IsTest
    static void acceptsBulkRequestWithoutDmlInLoops() {
        List<ServiceAppointment> appointments = createTransferredAppointments(200, 'bulk acceptance');
        List<Id> appointmentIds = new List<Id>();
        for (ServiceAppointment appointment : appointments) {
            appointmentIds.add(appointment.Id);
        }
        setAcceptancePermission(true);

        Test.startTest();
        List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> results = acceptAsTestUser(appointmentIds);
        Test.stopTest();

        Assert.areEqual(200, results.size(), 'Every selected appointment should have a result');
        for (HOT_TjenesteleverandorAcceptanceService.AcceptanceResult result : results) {
            Assert.isTrue(result.success, 'Every eligible bulk appointment should be accepted');
        }
        Assert.areEqual(
            200,
            [
                SELECT COUNT()
                FROM ServiceAppointment
                WHERE Id IN :appointmentIds AND HOT_TjenesteleverandorStatus__c = 'Accepted'
            ],
            'All selected appointments should be accepted'
        );
    }

    @IsTest
    static void repeatedAcceptanceIsIdempotent() {
        ServiceAppointment appointment = getTransferredAppointments(1)[0];
        appointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        update appointment;
        Datetime originalAcceptanceTime = getAppointment(appointment.Id).HOT_TjenesteleverandorAcceptDate__c;
        setAcceptancePermission(true);

        Test.startTest();
        List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> results = acceptAsTestUser(
            new List<Id>{ appointment.Id, appointment.Id }
        );
        Test.stopTest();

        ServiceAppointment actual = getAppointment(appointment.Id);
        Assert.areEqual(1, results.size(), 'Duplicate IDs should be processed once');
        Assert.isTrue(results[0].success, 'An already accepted appointment should be an idempotent success');
        Assert.areEqual(
            'Oppdraget er allerede akseptert.',
            results[0].message,
            'The result should explain the idempotent case'
        );
        Assert.areEqual(
            originalAcceptanceTime,
            actual.HOT_TjenesteleverandorAcceptDate__c,
            'Repeated acceptance must not replace the original acceptance time'
        );
    }

    @IsTest
    static void rejectsAppointmentAfterDeadline() {
        ServiceAppointment appointment = getTransferredAppointments(1)[0];
        appointment.HOT_TjenesteleverandorDeadline__c = System.now().addMinutes(-1);
        update appointment;
        setAcceptancePermission(true);

        Test.startTest();
        List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> results = acceptAsTestUser(
            new List<Id>{ appointment.Id }
        );
        Test.stopTest();

        Assert.isFalse(results[0].success, 'An appointment after its deadline must not be accepted');
        Assert.isTrue(
            results[0].message.contains('Svarfristen'),
            'The response should explain that the deadline has passed'
        );
        Assert.areNotEqual(
            'Accepted',
            getAppointment(appointment.Id).HOT_TjenesteleverandorStatus__c,
            'The expired appointment must not be accepted'
        );
    }

    @IsTest
    static void returnsPerRecordResultWhenAppointmentIsNotAcceptable() {
        List<ServiceAppointment> appointments = getTransferredAppointments(2);
        appointments[0].HOT_TjenesteleverandorStatus__c = 'Declined';
        update appointments[0];
        Account unrelatedRecord = HOT_TestDataFactory.createAccount(false);
        insert unrelatedRecord;
        setAcceptancePermission(true);

        Test.startTest();
        List<HOT_TjenesteleverandorAcceptanceService.AcceptanceResult> results = acceptAsTestUser(
            new List<Id>{ appointments[0].Id, unrelatedRecord.Id, appointments[1].Id }
        );
        Test.stopTest();

        Assert.areEqual(3, results.size(), 'Every unique requested ID should have a result');
        Assert.isFalse(results[0].success, 'A declined appointment cannot be accepted');
        Assert.isFalse(results[1].success, 'A non-Service-Appointment ID cannot be accepted');
        Assert.isTrue(results[2].success, 'Other eligible records in the same request should still succeed');
    }

    @IsTest
    static void rejectsUserWithoutAcceptancePermission() {
        ServiceAppointment appointment = getTransferredAppointments(1)[0];
        setAcceptancePermission(false);

        Test.startTest();
        try {
            acceptAsTestUser(new List<Id>{ appointment.Id });
            Assert.fail('A user without the custom permission should be rejected');
        } catch (AuraHandledException expected) {
            Assert.isNotNull(expected, 'The permission failure should be returned as a handled exception');
        }
        Test.stopTest();

        Assert.areEqual(
            'Transferred',
            getAppointment(appointment.Id).HOT_TjenesteleverandorStatus__c,
            'Permission failure must not change the appointment'
        );
    }

    @IsTest
    static void rejectsEmptySelection() {
        setAcceptancePermission(true);

        Test.startTest();
        try {
            acceptAsTestUser(new List<Id>());
            Assert.fail('An empty selection should be rejected');
        } catch (AuraHandledException expected) {
            Assert.isNotNull(expected, 'The validation failure should be returned as a handled exception');
        }
        Test.stopTest();
    }

    private static void setAcceptancePermission(Boolean hasPermission) {
        HOT_TjenesteleverandorAcceptanceService.permissionHelper = new CustomPermissionHelperStub()
            .addHasCustomPermission(hasPermission)
            .getMock();
    }

    private static List<ServiceAppointment> getTransferredAppointments(Integer count) {
        return [
            SELECT
                Id,
                Status,
                HOT_IsReleasedToFreelance__c,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorDeadline__c
            FROM ServiceAppointment
            WHERE HOT_TjenesteleverandorStatus__c = 'Transferred'
            ORDER BY CreatedDate
            LIMIT :count
        ];
    }

    private static ServiceAppointment getAppointment(Id appointmentId) {
        return [
            SELECT
                Status,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorAcceptDate__c,
                HOT_TjenesteleverandorDeadline__c
            FROM ServiceAppointment
            WHERE Id = :appointmentId
        ];
    }

    private static List<ServiceAppointment> createTransferredAppointments(Integer count, String subject) {
        WorkType workType = HOT_TestDataFactory.createWorkType(subject);
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest(subject, workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer index = 0; index < count; index++) {
            ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            appointments.add(appointment);
        }
        insert appointments;
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = 'Released to Freelance';
        }
        update appointments;
        return appointments;
    }
}
