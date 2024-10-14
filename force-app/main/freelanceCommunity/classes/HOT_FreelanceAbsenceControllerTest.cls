@isTest
private class HOT_FreelanceAbsenceControllerTest {
    static Integer CONFLICTING_WAGE_CLAIM_COUNT = 1;
    static Integer CONFLICTING_SA_COUNT = 1;
    static Integer TOTAL_SA_COUNT = 1;
    static Integer TOTAL_WAGE_CLAIM_COUNT = 1;
    static Integer ABSENCE_START_TIME_OFFSET_IN_HOURS = 1;
    static Integer ABSENCE_DURATION_IN_HOURS = 2;

    @testSetup
    static void setup() {
        Profile otherUserProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];

        User otherUser = HOT_TestDataFactory.createUser('Bruker', otherUserProfile);
        insert otherUser;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        Integer appointmentDurationInMinutes = (60 * ABSENCE_DURATION_IN_HOURS) / TOTAL_SA_COUNT;
        for (Integer i = 0; i < TOTAL_SA_COUNT; i++) {
            HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTest', workType);

            if (i < CONFLICTING_SA_COUNT) {
                request.StartTime__c = Datetime.now()
                    .addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS)
                    .addMinutes(i * appointmentDurationInMinutes);
                request.EndTime__c = Datetime.now()
                    .addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS)
                    .addMinutes((Integer) (0.9 * (i + 1) * appointmentDurationInMinutes));
            } else {
                request.StartTime__c = Datetime.now().addDays(1).addMinutes(i * appointmentDurationInMinutes);
                request.EndTime__c = Datetime.now()
                    .addDays(1)
                    .addMinutes((Integer) (0.9 * (i + 1) * appointmentDurationInMinutes));
            }
            insert request;
            request.Status__c = 'Godkjent';
            update request;

            WorkOrder workOrder = [SELECT Id FROM WorkOrder WHERE HOT_Request__c = :request.Id];

            WorkOrderLineItem workOrderLineItem = [SELECT Id FROM WOrkOrderLineItem WHERE WorkOrderId = :workOrder.Id];

            ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            serviceAppointment.SchedStartTime = request.StartTime__c;
            serviceAppointment.EarliestStartTime = serviceAppointment.SchedStartTime;
            serviceAppointment.SchedEndTime = request.EndTime__c;
            serviceAppointment.DueDate = serviceAppointment.SchedEndTime;
            serviceAppointment.Status = 'Dispatched';
            insert serviceAppointment;
            System.debug('Andre' + serviceAppointment);
            AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
                serviceAppointment.Id,
                serviceResource.Id
            );
            insert assignedResource;
            serviceAppointment.HOT_AssignedResourceId__c = UserInfo.getUserId();
            update serviceAppointment;
        }

        ResourceAbsence absence = new ResourceAbsence();
        absence.Start = Datetime.now();
        absence.End = Datetime.now().addHours(1);
        absence.Type = 'Vacation';
        absence.ResourceId = serviceResource.Id;
        insert absence;

        for (Integer i = 0; i < TOTAL_WAGE_CLAIM_COUNT; i++) {
            HOT_WageClaim__c openClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
            openClaim.Status__c = 'Open';
            if (i < CONFLICTING_WAGE_CLAIM_COUNT) {
                openClaim.StartTime__c = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS);
                openClaim.EndTime__c = openClaim.StartTime__c.addHours(ABSENCE_DURATION_IN_HOURS);
            } else {
                openClaim.StartTime__c = Datetime.now().addDays(1);
                openClaim.EndTime__c = Datetime.now().addDays(1).addHours(1);
            }
            System.debug('Andre' + openClaim);
            insert openClaim;
        }
    }

    @IsTest
    static void getConflictsForTimePeriodTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addHours(ABSENCE_DURATION_IN_HOURS).addMinutes(1);
        System.debug('Andre' + absenceStart + absenceEnd);

        Test.startTest();
        HOT_FreelanceAbsenceController.ConflictingRecord[] conflicts = HOT_FreelanceAbsenceController.getConflictsForTimePeriod(
            absenceStart.getTime(),
            absenceEnd.getTime()
        );
        Test.stopTest();

        System.assertEquals(
            CONFLICTING_SA_COUNT + CONFLICTING_WAGE_CLAIM_COUNT,
            conflicts.size(),
            'Should retrieve conflicts for given time period'
        );
    }

    @IsTest
    static void getConflictsForTimePeriodErronousDurationTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addMinutes(-30);
        Exception getConflictsException = null;

        Test.startTest();
        try {
            HOT_FreelanceAbsenceController.getConflictsForTimePeriod(absenceStart.getTime(), absenceEnd.getTime());
        } catch (Exception e) {
            getConflictsException = e;
        }
        Test.stopTest();

        System.assertEquals(
            HOT_FreelanceAbsenceController.ERROR_INVALID_START_AND_END_TIME,
            getConflictsException.getMessage(),
            'Should throw an exception if start time comes after end time'
        );
    }

    @Istest
    static void resolveConflictsForTimePeriodTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addHours(ABSENCE_DURATION_IN_HOURS).addMinutes(1);
        HOT_FreelanceAbsenceController.ConflictingRecord[] conflictsBeforeResolution = HOT_FreelanceAbsenceController.getConflictsForTimePeriod(
            absenceStart.getTime(),
            absenceEnd.getTime()
        );

        Test.startTest();
        HOT_FreelanceAbsenceController.resolveConflictsForTimePeriod(absenceStart, absenceEnd, 'Test');
        Test.stopTest();

        HOT_FreelanceAbsenceController.ConflictingRecord[] conflictsAfterResolution = HOT_FreelanceAbsenceController.getConflictsForTimePeriod(
            absenceStart.getTime(),
            absenceEnd.getTime()
        );

        System.assert(
            !conflictsBeforeResolution.isEmpty() && conflictsAfterResolution.isEmpty(),
            'Should remove conflicts for given time period'
        );
    }

    @IsTest
    static void getConflictingServiceAppointmentsTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addHours(ABSENCE_DURATION_IN_HOURS).addMinutes(1);
        ServiceAppointment[] conflictingAppointments = null;

        Test.startTest();
        conflictingAppointments = HOT_FreelanceAbsenceController.getConflictingServiceAppointments(
            absenceStart,
            absenceEnd
        );
        Test.stopTest();

        System.assertEquals(
            CONFLICTING_SA_COUNT,
            conflictingAppointments.size(),
            'should retrieve conflicting ServiceAppointment'
        );
    }

    @IsTest
    static void getConflictingOpenWageClaimsTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addHours(ABSENCE_DURATION_IN_HOURS).addMinutes(1);
        HOT_WageClaim__c[] conflictingClaims = null;

        Test.startTest();
        conflictingClaims = HOT_FreelanceAbsenceController.getConflictingOpenWageClaims(absenceStart, absenceEnd);
        Test.stopTest();

        System.assertEquals(
            CONFLICTING_WAGE_CLAIM_COUNT,
            conflictingClaims.size(),
            'Should retrieve conflicting open wageclaim'
        );
    }

    @IsTest
    static void deleteAbsenceTest() {
        Id resourceId = HOT_FreelanceAbsenceController.getUserServiceResourceId();
        ResourceAbsence[] absences = [SELECT Id FROM ResourceAbsence WHERE ResourceId = :resourceId];

        Test.startTest();
        for (ResourceAbsence absence : absences) {
            HOT_FreelanceAbsenceController.deleteAbsence(absence.Id);
        }
        Test.stopTest();

        ResourceAbsence[] remainingAbsences = [SELECT Id FROM ResourceAbsence WHERE ResourceId = :resourceId];

        System.assert(absences.size() == 1 && remainingAbsences.isEmpty(), 'shoud delete users absences');
    }

    @IsTest
    static void deleteAbsenceTwiceTest() {
        Id resourceId = HOT_FreelanceAbsenceController.getUserServiceResourceId();
        ResourceAbsence absence = [SELECT Id FROM ResourceAbsence WHERE ResourceId = :resourceId LIMIT 1];
        Exception deletionException = null;

        Test.startTest();
        try {
            HOT_FreelanceAbsenceController.deleteAbsence(absence.Id);
            HOT_FreelanceAbsenceController.deleteAbsence(absence.Id);
        } catch (Exception e) {
            deletionException = e;
        }
        Test.stopTest();

        System.assertEquals(
            HOT_FreelanceAbsenceController.ERROR_RESOURCE_ABSENCE_NOT_FOUND,
            deletionException.getMessage(),
            'Attempting to delete a record that doesnt exist should result in an exception'
        );
    }

    @IsTest
    static void deleteAbsenceAsOtherUser() {
        User otherUser = [SELECT Id FROM User WHERE LastName = 'Bruker'];
        Id resourceId = HOT_FreelanceAbsenceController.getUserServiceResourceId();
        ResourceAbsence absence = [SELECT Id FROM ResourceAbsence WHERE ResourceId = :resourceId LIMIT 1];
        Exception deletionException = null;

        Test.startTest();
        System.runAs(otherUser) {
            try {
                HOT_FreelanceAbsenceController.deleteAbsence(absence.Id);
            } catch (Exception e) {
                deletionException = e;
            }
        }
        Test.stopTest();

        System.assertEquals(
            HOT_FreelanceAbsenceController.ERROR_RESOURCE_ABSENCE_NO_ACCESS,
            deletionException.getMessage(),
            'Trying to delete an existing record without being the correct user should result in an exception'
        );
    }
}
