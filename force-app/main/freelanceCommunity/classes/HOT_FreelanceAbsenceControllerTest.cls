@isTest
private class HOT_FreelanceAbsenceControllerTest {
    static Integer CONFLICTING_WAGE_CLAIM_COUNT = 1;
    static Integer CONFLICTING_SA_COUNT = 1;
    static Integer TOTAL_SA_COUNT = CONFLICTING_SA_COUNT + 1;
    static Integer TOTAL_WAGE_CLAIM_COUNT = CONFLICTING_WAGE_CLAIM_COUNT + 1;
    static Integer ABSENCE_START_TIME_OFFSET_IN_HOURS = 1;
    static Integer ABSENCE_DURATION_IN_HOURS = 2;

    @testSetup
    static void setup() {
        Integer appointmentDurationInMinutes = (60 * ABSENCE_DURATION_IN_HOURS) / TOTAL_SA_COUNT;

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

        HOT_Request__c[] requests = new List<HOT_Request__c>();
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
            requests.add(request);
        }

        insert requests;

        for (HOT_Request__c request : requests) {
            request.Status__c = 'Godkjent';
        }

        update requests;

        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(
            [SELECT Id, HOT_Request__c FROM WorkOrder WHERE HOT_Request__c IN :requests]
        );

        WorkOrderLineItem[] lineItems = [
            SELECT Id, WorkOrderId
            FROM WOrkOrderLineItem
            WHERE WorkOrderId IN :workOrders.keySet()
        ];

        Map<Id, WorkOrderLineItem> woToLineItems = new Map<Id, WorkOrderLineItem>();
        for (WorkOrderLineItem li : lineItems) {
            woToLineItems.put(li.WorkOrderId, li);
        }

        Map<Id, WorkOrderLineItem> requestIdToWOLI = new Map<Id, WorkOrderLineItem>();
        for (WorkOrder wo : workOrders.values()) {
            WorkOrderLineItem li = woToLineItems.get(wo.Id);
            if (li != null) {
                requestIdToWOLI.put(wo.HOT_Request__c, li);
            }
        }

        ServiceAppointment[] serviceAppointments = new List<ServiceAppointment>();
        for (HOT_Request__c request : requests) {
            WorkOrderLineItem lineItem = requestIdToWOLI.get(request.Id);
            if (lineItem != null) {
                ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(lineItem);
                serviceAppointment.SchedStartTime = request.StartTime__c;
                serviceAppointment.EarliestStartTime = serviceAppointment.SchedStartTime;
                serviceAppointment.SchedEndTime = request.EndTime__c;
                serviceAppointment.DueDate = serviceAppointment.SchedEndTime;
                serviceAppointment.Status = 'Dispatched';
                serviceAppointments.add(serviceAppointment);
            }
        }

        insert serviceAppointments;

        AssignedResource[] assignedResources = new List<AssignedResource>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
                serviceAppointment.Id,
                serviceResource.Id
            );
            assignedResources.add(assignedResource);
        }

        insert assignedResources;

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_AssignedResourceId__c = UserInfo.getUserId();
        }

        update serviceAppointments;

        ResourceAbsence absence = new ResourceAbsence();
        absence.Start = Datetime.now();
        absence.End = Datetime.now().addHours(1);
        absence.Type = 'Vacation';
        absence.ResourceId = serviceResource.Id;
        insert absence;

        Event event = new Event();
        event.WhatId = absence.Id;
        event.StartDateTime = absence.Start;
        event.EndDateTime = absence.End;
        insert event;

        absence.HOT_EventId__c = event.Id;
        update absence;

        HOT_WageClaim__c[] wageClaims = new List<HOT_WageClaim__c>();
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
            wageClaims.add(openClaim);
        }

        insert wageClaims;
    }

    @IsTest
    static void createAbsenceAndResolveConflictsTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addHours(ABSENCE_DURATION_IN_HOURS).addMinutes(1);
        HOT_FreelanceAbsenceController.ConflictingRecord[] conflictsBeforeResolution = HOT_FreelanceAbsenceController.getConflictsForTimePeriod(
            absenceStart.getTime(),
            absenceEnd.getTime()
        );

        Test.startTest();
        HOT_FreelanceAbsenceController.createAbsenceAndResolveConflicts(
            absenceStart.getTime(),
            absenceEnd.getTime(),
            'Vacation'
        );
        Test.stopTest();

        HOT_FreelanceAbsenceController.ConflictingRecord[] conflictsAfterResolution = HOT_FreelanceAbsenceController.getConflictsForTimePeriod(
            absenceStart.getTime(),
            absenceEnd.getTime()
        );

        ResourceAbsence absence = [
            SELECT Id
            FROM ResourceAbsence
            WHERE Start = :absenceStart AND End = :absenceEnd
            LIMIT 1
        ];

        Event[] relatedEvents = [
            SELECT Id
            FROM Event
            WHERE WhatId = :absence.Id
        ];

        System.assert(
            relatedEvents.size() == 1 &&
                absence != null &&
                conflictsBeforeResolution.size() == CONFLICTING_SA_COUNT + CONFLICTING_WAGE_CLAIM_COUNT &&
                conflictsAfterResolution.isEmpty(),
            'Should remove conflicts for given time period and create absence'
        );
    }

    @IsTest
    static void createAbsenceAndResolveConflictsInvalidTypeTest() {
        Exception createAbsenceException = null;
        Test.startTest();
        try {
            HOT_FreelanceAbsenceController.createAbsenceAndResolveConflicts(
                Datetime.now().getTime(),
                Datetime.now().addMinutes(1).getTime(),
                'Invalid type'
            );
        } catch (Exception e) {
            createAbsenceException = e;
        }
        Test.stopTest();

        System.assertEquals(
            HOT_FreelanceAbsenceController.ERROR_INVALID_ABSENCE_TYPE,
            createAbsenceException.getMessage(),
            'Should raise exception when providing an invalid absence type'
        );
    }

    @IsTest
    static void createAbsenceAndResolveConflictsInvalidDates() {
        Exception createAbsenceException = null;
        Test.startTest();
        try {
            HOT_FreelanceAbsenceController.createAbsenceAndResolveConflicts(
                Datetime.now().getTime(),
                Datetime.now().addMinutes(-1).getTime(),
                'Vacation'
            );
        } catch (Exception e) {
            createAbsenceException = e;
        }
        Test.stopTest();

        System.assertEquals(
            HOT_FreelanceAbsenceController.ERROR_INVALID_START_AND_END_TIME,
            createAbsenceException.getMessage(),
            'Should raise exception when providing an invalid absence type'
        );
    }

    @IsTest
    static void getConflictsForTimePeriodTest() {
        Datetime absenceStart = Datetime.now().addHours(ABSENCE_START_TIME_OFFSET_IN_HOURS).addMinutes(1);
        Datetime absenceEnd = absenceStart.addHours(ABSENCE_DURATION_IN_HOURS).addMinutes(1);

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
        ResourceAbsence absence = [SELECT Id FROM ResourceAbsence WHERE ResourceId = :resourceId LIMIT 1];
        Id absenceId = absence.Id;

        Test.startTest();
        HOT_FreelanceAbsenceController.deleteAbsence(absence.Id);
        Test.stopTest();

        ResourceAbsence[] remainingAbsence = [SELECT Id FROM ResourceAbsence WHERE Id = :absenceId];
        Event[] remainingEvent = [SELECT Id FROM Event WHERE WhatId = :absenceId];

        System.assert(
            remainingAbsence.isEmpty() && remainingEvent.isEmpty(),
            'shoud delete ResourceAbsence and related Event'
        );
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

    @IsTest
    static void logExceptionTest() {
        Boolean isLoggingSuccessful = false;
        Id eventId = null;
        Exception testException = new NoAccessException();
        Test.startTest();
        isLoggingSuccessful = HOT_FreelanceAbsenceController.logException(testException, null);
        Test.stopTest();

        System.assert(isLoggingSuccessful, 'Should succesfully log exception');
    }
}
