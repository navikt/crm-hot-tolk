@IsTest
private class HOT_TjenesteleverandorReleaseServiceTest {
    private static final String TEST_USERNAME =
        'tjenesteleverandor-release-' +
        UserInfo.getOrganizationId() +
        '@test.nav.no';

    @TestSetup
    static void createAppointments() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = HOT_TestDataFactory.createUser('TLRelease', profile);
        testUser.Username = TEST_USERNAME;
        testUser.Alias = 'tlrel';
        testUser.CommunityNickname = 'tlrelease' + UserInfo.getOrganizationId();
        testUser.LanguageLocaleKey = 'en_US';
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Admin' LIMIT 1];

        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUser;
            insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permissionSet.Id);
        }

        WorkType workType = HOT_TestDataFactory.createWorkType('supplier release');
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('supplier release', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer index = 0; index < 2; index++) {
            appointments.add(HOT_TestDataFactory.createServiceAppointment(workOrderLineItem));
        }
        insert appointments;
        List<ServiceAppointment> transfers = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            transfers.add(
                new ServiceAppointment(
                    Id = appointment.Id,
                    Status = 'None',
                    HOT_IsReleasedToTjenesteleverandor__c = true,
                    HOT_TjenesteleverandorStatus__c = 'Transferred'
                )
            );
        }
        update transfers;

        List<ServiceAppointment> acceptances = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            acceptances.add(
                new ServiceAppointment(
                    Id = appointment.Id,
                    HOT_TjenesteleverandorStatus__c = 'Accepted',
                    HOT_DeadlineDate__c = Date.today().addDays(1),
                    HOT_FreelanceSubject__c = 'Original release subject'
                )
            );
        }
        update acceptances;
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Username = :TEST_USERNAME LIMIT 1];
    }

    private static List<ServiceAppointment> getAppointments() {
        return [
            SELECT Id, Status, HOT_DeadlineDate__c, HOT_FreelanceSubject__c
            FROM ServiceAppointment
            WHERE HOT_FreelanceSubject__c = 'Original release subject'
            ORDER BY Id
        ];
    }

    private static void assertRejected(List<ServiceAppointment> appointments) {
        System.runAs(getTestUser()) {
            try {
                HOT_TjenesteleverandorReleaseService.releaseServiceAppointments(appointments);
                Assert.fail('Invalid release requests must be rejected');
            } catch (AuraHandledException expected) {
                Assert.isNotNull(expected);
            }
        }
    }

    private static void assertUnchanged(Set<Id> appointmentIds) {
        List<ServiceAppointment> appointments = [
            SELECT Status, HOT_DeadlineDate__c, HOT_FreelanceSubject__c
            FROM ServiceAppointment
            WHERE Id IN :appointmentIds
        ];
        Assert.areEqual(appointmentIds.size(), appointments.size());
        for (ServiceAppointment appointment : appointments) {
            Assert.areEqual('None', appointment.Status);
            Assert.areEqual(Date.today().addDays(1), appointment.HOT_DeadlineDate__c);
            Assert.areEqual('Original release subject', appointment.HOT_FreelanceSubject__c);
        }
    }

    @IsTest
    static void releasesSelectedSA() {
        List<ServiceAppointment> appointments = getAppointments();
        Assert.areEqual(2, appointments.size());
        for (ServiceAppointment appointment : appointments) {
            appointment.HOT_DeadlineDate__c = Date.today().addDays(2);
            appointment.HOT_FreelanceSubject__c = 'Updated release subject';
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
        List<ServiceAppointment> releasedAppointments = [
            SELECT Status, HOT_DeadlineDate__c, HOT_FreelanceSubject__c, HOT_IsReleasedToFreelance__c
            FROM ServiceAppointment
            WHERE Id IN :appointments
        ];
        Assert.areEqual(2, releasedAppointments.size());
        for (ServiceAppointment appointment : releasedAppointments) {
            Assert.areEqual('Released to Freelance', appointment.Status);
            Assert.areEqual(Date.today().addDays(2), appointment.HOT_DeadlineDate__c);
            Assert.areEqual('Updated release subject', appointment.HOT_FreelanceSubject__c);
            Assert.isTrue(appointment.HOT_IsReleasedToFreelance__c);
        }
    }

    @IsTest
    static void rejectsInvalidRequestSizes() {
        List<ServiceAppointment> appointments = getAppointments();
        List<ServiceAppointment> oversizedRequest = new List<ServiceAppointment>();
        for (Integer index = 0; index < 201; index++) {
            oversizedRequest.add(appointments[0]);
        }
        System.Test.startTest();
        assertRejected(null);
        assertRejected(new List<ServiceAppointment>());
        assertRejected(oversizedRequest);
        System.Test.stopTest();
        assertUnchanged(new Map<Id, ServiceAppointment>(appointments).keySet());
    }

    @IsTest
    static void rejectsInvalidSAEntries() {
        List<ServiceAppointment> appointments = getAppointments();
        System.Test.startTest();
        assertRejected(new List<ServiceAppointment>{ null });
        assertRejected(new List<ServiceAppointment>{ new ServiceAppointment() });
        assertRejected(new List<ServiceAppointment>{ appointments[0], appointments[0] });
        System.Test.stopTest();
        assertUnchanged(new Map<Id, ServiceAppointment>(appointments).keySet());
    }

    @IsTest
    static void rejectsMissingDeadlineAtomically() {
        List<ServiceAppointment> appointments = getAppointments();
        appointments[0].HOT_FreelanceSubject__c = 'Must not be saved';
        appointments[1].HOT_DeadlineDate__c = null;
        System.Test.startTest();
        assertRejected(appointments);
        System.Test.stopTest();
        assertUnchanged(new Map<Id, ServiceAppointment>(appointments).keySet());
    }

    @IsTest
    static void rejectsBlankAndOverlongSubjects() {
        List<ServiceAppointment> appointments = getAppointments();
        System.Test.startTest();
        appointments[1].HOT_FreelanceSubject__c = null;
        assertRejected(appointments);
        appointments[1].HOT_FreelanceSubject__c = '   ';
        assertRejected(appointments);
        appointments[1].HOT_FreelanceSubject__c = 'x'.repeat(256);
        assertRejected(appointments);
        System.Test.stopTest();
        assertUnchanged(new Map<Id, ServiceAppointment>(appointments).keySet());
    }

    @IsTest
    static void rejectsChangedStatusAtomically() {
        List<ServiceAppointment> appointments = getAppointments();
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);
        update new ServiceAppointment(Id = appointments[1].Id, Status = 'Scheduled');
        System.Test.startTest();
        assertRejected(appointments);
        System.Test.stopTest();
        assertUnchanged(new Set<Id>{ appointments[0].Id });
        Assert.areEqual('Scheduled', [SELECT Status FROM ServiceAppointment WHERE Id = :appointments[1].Id].Status);
    }

    @IsTest
    static void rejectsUnacceptedSA() {
        List<ServiceAppointment> appointments = getAppointments();
        update new ServiceAppointment(Id = appointments[1].Id, HOT_TjenesteleverandorStatus__c = 'Transferred');
        System.Test.startTest();
        assertRejected(appointments);
        System.Test.stopTest();
        assertUnchanged(new Map<Id, ServiceAppointment>(appointments).keySet());
    }

    @IsTest
    static void rejectsSANotReleasedToSupplier() {
        List<ServiceAppointment> appointments = getAppointments();
        update new ServiceAppointment(Id = appointments[1].Id, HOT_IsReleasedToTjenesteleverandor__c = false);
        System.Test.startTest();
        assertRejected(appointments);
        System.Test.stopTest();
        assertUnchanged(new Map<Id, ServiceAppointment>(appointments).keySet());
    }
}
