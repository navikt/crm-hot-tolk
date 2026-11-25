@IsTest
private class HOT_EventControllerTest {
    @TestSetup
    static void createOwners() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
            LIMIT 1
        ];
        List<User> owners = new List<User>();
        for (String name : new List<String>{ 'EventOld', 'EventNew' }) {
            User owner = HOT_TestDataFactory.createUser(name, profile);
            owner.Username =
                name +
                '.' +
                UserInfo.getOrganizationId() +
                '.' +
                Datetime.now().getTime() +
                '@example.test';
            owners.add(owner);
        }
        insert owners;
    }

    private static Map<String, Id> getOwners() {
        Map<String, Id> owners = new Map<String, Id>();
        for (User owner : [SELECT Id, LastName FROM User WHERE LastName IN ('EventOld', 'EventNew')]) {
            owners.put(owner.LastName, owner.Id);
        }
        return owners;
    }

    private static List<ServiceAppointment> createAppointments(Integer count) {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.ShouldAutoCreateSvcAppt = false;
        insert workType;
        // Keep the factory's open request: only approved requests generate child line items.
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_EventControllerTest', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem lineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        // The line-item handler normally creates SAs. Bypass it only while inserting this
        // parent so the fixture owns the exact appointment count, including the bulk case.
        MyTriggers.disable(HOT_WorkOrderLineItemHandler.class);
        try {
            insert lineItem;
        } finally {
            MyTriggers.enable(HOT_WorkOrderLineItemHandler.class);
        }

        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer i = 0; i < count; i++) {
            appointments.add(HOT_TestDataFactory.createServiceAppointment(lineItem));
        }
        insert appointments;
        Assert.areEqual(
            count,
            [SELECT COUNT() FROM ServiceAppointment WHERE HOT_Request__c = :request.Id],
            'Create exactly the explicit appointment fixtures without automation-generated duplicates'
        );
        return appointments;
    }

    private static Map<Id, Event> createEvents(List<ServiceAppointment> appointments, Id ownerId) {
        List<Event> events = new List<Event>();
        Id eventRecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName()
            .get('HOT_Events')
            .getRecordTypeId();
        Datetime startTime = Datetime.newInstance(Date.today().addDays(2), Time.newInstance(10, 0, 0, 0));
        for (ServiceAppointment appointment : appointments) {
            // Explicit existing Event fixtures, not a request for managed Field Service calendar sync.
            // Persisted appointments remain undispatched and have no AssignedResource.
            events.add(
                new Event(
                    RecordTypeId = eventRecordTypeId,
                    WhatId = appointment.Id,
                    OwnerId = ownerId,
                    Subject = 'Existing calendar event',
                    StartDateTime = startTime,
                    EndDateTime = startTime.addHours(1)
                )
            );
        }
        insert events;
        Map<Id, Event> eventsByAppointment = new Map<Id, Event>();
        for (Event ev : events) {
            eventsByAppointment.put(ev.WhatId, ev);
        }
        return eventsByAppointment;
    }

    private static ServiceAppointment snapshot(Id appointmentId, Id ownerId, Datetime startTime) {
        return (ServiceAppointment) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'Id' => appointmentId,
                    'Status' => 'Dispatched',
                    'HOT_AssignedResourceId__c' => ownerId,
                    'HOT_IsEmployedInterpreter__c' => true,
                    'SchedStartTime' => startTime,
                    'SchedEndTime' => startTime == null ? null : startTime.addHours(1)
                }
            ),
            ServiceAppointment.class
        );
    }

    private static Map<Id, Event> getEvents(Set<Id> appointmentIds) {
        Map<Id, Event> eventsByAppointment = new Map<Id, Event>();
        for (Event ev : [
            SELECT Id, WhatId, OwnerId
            FROM Event
            WHERE WhatId IN :appointmentIds
        ]) {
            eventsByAppointment.put(ev.WhatId, ev);
        }
        return eventsByAppointment;
    }

    private static void assertEvent(Event beforeEvent, Event afterEvent, Id expectedOwner) {
        Assert.isNotNull(afterEvent, 'The existing event must not be deleted');
        Assert.areEqual(beforeEvent.Id, afterEvent.Id, 'Update the existing event instead of replacing it');
        Assert.areEqual(beforeEvent.WhatId, afterEvent.WhatId, 'Keep the appointment relationship');
        Assert.areEqual(expectedOwner, afterEvent.OwnerId, 'Copy the assigned user when eligible');
    }

    @IsTest
    static void reassignmentUpdatesOwnerEvenForPastAppointment() {
        Map<String, Id> owners = getOwners();
        List<ServiceAppointment> appointments = createAppointments(1);
        Id appointmentId = appointments[0].Id;
        Map<Id, Event> beforeEvents = createEvents(appointments, owners.get('EventOld'));
        Datetime pastStart = Datetime.now().addDays(-2);
        ServiceAppointment oldAppointment = snapshot(
            appointmentId,
            owners.get('EventOld'),
            pastStart
        );
        ServiceAppointment updatedAppointment = snapshot(
            appointmentId,
            owners.get('EventNew'),
            pastStart
        );

        Test.startTest();
        HOT_EventController.updateServiceAppointmentEvents(
            new List<ServiceAppointment>{ updatedAppointment },
            new Map<Id, SObject>{ appointmentId => oldAppointment }
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Event WHERE WhatId = :appointmentId],
            'Do not create a replacement event'
        );
        assertEvent(
            beforeEvents.get(appointmentId),
            getEvents(beforeEvents.keySet()).get(appointmentId),
            owners.get('EventNew')
        );
    }

    @IsTest
    static void ineligibleAndUnrelatedChangesLeaveEventsUntouched() {
        Map<String, Id> owners = getOwners();
        List<ServiceAppointment> appointments = createAppointments(7);
        Map<Id, Event> beforeEvents = createEvents(appointments, owners.get('EventOld'));
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Datetime futureStart = Datetime.now().addDays(2);
        for (ServiceAppointment appointment : appointments) {
            oldMap.put(
                appointment.Id,
                snapshot(appointment.Id, owners.get('EventOld'), futureStart)
            );
            updatedAppointments.add(snapshot(appointment.Id, owners.get('EventOld'), futureStart));
        }

        updatedAppointments[0].HOT_AssignedResourceId__c = null; // Resource removed.
        updatedAppointments[1].Status = 'Scheduled';
        updatedAppointments[1].HOT_AssignedResourceId__c = owners.get('EventNew');
        updatedAppointments[2].Status = 'Completed';
        updatedAppointments[2].HOT_AssignedResourceId__c = owners.get('EventNew');
        updatedAppointments[3].HOT_IsEmployedInterpreter__c = false;
        updatedAppointments[3].HOT_AssignedResourceId__c = owners.get('EventNew');
        // Index 4 is completely unchanged.
        ((ServiceAppointment) oldMap.get(appointments[5].Id)).HOT_AssignedResourceId__c = null; // First assignment.
        ((ServiceAppointment) oldMap.get(appointments[6].Id)).Status = 'Scheduled';

        Test.startTest();
        Integer dmlBefore = Limits.getDmlStatements();
        HOT_EventController.updateServiceAppointmentEvents(updatedAppointments, oldMap);
        Assert.areEqual(dmlBefore, Limits.getDmlStatements(), 'Ineligible changes must not issue Event DML');
        Test.stopTest();

        Map<Id, Event> afterEvents = getEvents(beforeEvents.keySet());
        Assert.areEqual(
            appointments.size(),
            [SELECT COUNT() FROM Event WHERE WhatId IN :beforeEvents.keySet()],
            'Do not create or delete events'
        );
        for (ServiceAppointment appointment : appointments) {
            assertEvent(
                beforeEvents.get(appointment.Id),
                afterEvents.get(appointment.Id),
                owners.get('EventOld')
            );
        }
    }

    @IsTest
    static void reassignmentWithoutExistingEventDoesNotCreateOne() {
        Map<String, Id> owners = getOwners();
        List<ServiceAppointment> appointments = createAppointments(1);
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Datetime futureStart = Datetime.now().addDays(2);
        for (Integer i = 0; i < appointments.size(); i++) {
            Id appointmentId = appointments[i].Id;
            oldMap.put(appointmentId, snapshot(appointmentId, owners.get('EventOld'), futureStart));
            updatedAppointments.add(
                snapshot(appointmentId, owners.get('EventNew'), futureStart)
            );
        }
        Set<Id> appointmentIds = oldMap.keySet();
        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Event WHERE WhatId IN :appointmentIds],
            'No managed sync fixtures expected'
        );

        Test.startTest();
        Integer dmlBefore = Limits.getDmlStatements();
        HOT_EventController.updateServiceAppointmentEvents(updatedAppointments, oldMap);
        Assert.areEqual(dmlBefore, Limits.getDmlStatements(), 'Missing events must not cause custom DML');
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Event WHERE WhatId IN :appointmentIds],
            'Only standard sync creates events'
        );
    }

    @IsTest
    static void updatesTwoHundredExistingEventsInBulk() {
        Map<String, Id> owners = getOwners();
        List<ServiceAppointment> appointments = createAppointments(200);
        Map<Id, Event> beforeEvents = createEvents(appointments, owners.get('EventOld'));
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Datetime futureStart = Datetime.now().addDays(2);
        for (Integer i = 0; i < appointments.size(); i++) {
            Id appointmentId = appointments[i].Id;
            oldMap.put(
                appointmentId,
                snapshot(appointmentId, owners.get('EventOld'), futureStart)
            );
            updatedAppointments.add(
                snapshot(appointmentId, owners.get('EventNew'), futureStart)
            );
        }

        Test.startTest();
        HOT_EventController.updateServiceAppointmentEvents(updatedAppointments, oldMap);
        Test.stopTest();

        Map<Id, Event> afterEvents = getEvents(beforeEvents.keySet());
        Assert.areEqual(
            200,
            [SELECT COUNT() FROM Event WHERE WhatId IN :beforeEvents.keySet()],
            'Keep exactly the existing events'
        );
        for (ServiceAppointment appointment : updatedAppointments) {
            assertEvent(
                beforeEvents.get(appointment.Id),
                afterEvents.get(appointment.Id),
                owners.get('EventNew')
            );
        }
    }

    @IsTest
    static void missingEventMapEntryDoesNotPreventOtherUpdates() {
        Map<String, Id> owners = getOwners();
        List<ServiceAppointment> appointments = createAppointments(2);
        Id existingAppointmentId = appointments[0].Id;
        Id missingAppointmentId = appointments[1].Id;
        Map<Id, Event> beforeEvents = createEvents(
            new List<ServiceAppointment>{ appointments[0] },
            owners.get('EventOld')
        );
        Map<Id, ServiceAppointment> updatedAppointments = new Map<Id, ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            updatedAppointments.put(
                appointment.Id,
                snapshot(appointment.Id, owners.get('EventNew'), Datetime.now().addDays(2))
            );
        }

        Test.startTest();
        HOT_EventController.updateExistingEvents(beforeEvents, updatedAppointments);
        Test.stopTest();

        Map<Id, Event> afterEvents = getEvents(updatedAppointments.keySet());
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Event WHERE WhatId IN :updatedAppointments.keySet()],
            'Only the existing event should remain'
        );
        Assert.isFalse(
            afterEvents.containsKey(missingAppointmentId),
            'Skip missing map entries without creating events'
        );
        assertEvent(
            beforeEvents.get(existingAppointmentId),
            afterEvents.get(existingAppointmentId),
            owners.get('EventNew')
        );
    }

    @IsTest
    static void failedEventUpdateIsCaughtAndLeavesBatchUnchanged() {
        Map<String, Id> owners = getOwners();
        List<ServiceAppointment> appointments = createAppointments(2);
        Map<Id, Event> beforeEvents = createEvents(appointments, owners.get('EventOld'));
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Datetime futureStart = Datetime.now().addDays(2);
        for (Integer i = 0; i < appointments.size(); i++) {
            Id appointmentId = appointments[i].Id;
            oldMap.put(appointmentId, snapshot(appointmentId, owners.get('EventOld'), futureStart));
            updatedAppointments.add(
                snapshot(
                    appointmentId,
                    i == 0 ? appointmentId : owners.get('EventNew'),
                    futureStart
                )
            );
        }

        Test.startTest();
        Integer dmlBefore = Limits.getDmlStatements();
        // The DML exception must be caught and logged rather than escaping to the SA caller.
        HOT_EventController.updateServiceAppointmentEvents(updatedAppointments, oldMap);
        Assert.isTrue(Limits.getDmlStatements() > dmlBefore, 'The controller must attempt the eligible Event update');
        Test.stopTest();

        Map<Id, Event> afterEvents = getEvents(beforeEvents.keySet());
        Assert.areEqual(
            2,
            [SELECT COUNT() FROM Event WHERE WhatId IN :beforeEvents.keySet()],
            'A failed update must not create or delete events'
        );
        // The custom controller uses an all-or-none update: even the valid event stays unchanged.
        for (ServiceAppointment appointment : appointments) {
            assertEvent(
                beforeEvents.get(appointment.Id),
                afterEvents.get(appointment.Id),
                owners.get('EventOld')
            );
        }
    }

    @IsTest
    static void emptyInputsAndMissingEventMapEntriesDoNotIssueDml() {
        Id appointmentId = createAppointments(1)[0].Id;
        ServiceAppointment appointment = snapshot(appointmentId, UserInfo.getUserId(), null);

        Test.startTest();
        Integer dmlBefore = Limits.getDmlStatements();
        HOT_EventController.updateServiceAppointmentEvents(new List<ServiceAppointment>(), new Map<Id, SObject>());
        HOT_EventController.updateExistingEvents(new Map<Id, Event>(), new Map<Id, ServiceAppointment>());
        HOT_EventController.updateExistingEvents(
            new Map<Id, Event>(),
            new Map<Id, ServiceAppointment>{ appointmentId => appointment }
        );
        Assert.areEqual(dmlBefore, Limits.getDmlStatements(), 'Empty or missing event entries must be safe no-ops');
        Test.stopTest();
    }
}
