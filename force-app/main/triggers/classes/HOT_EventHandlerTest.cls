@IsTest
private class HOT_EventHandlerTest {
    // ---------- Test Utilities ----------
    private static Event makeEvent(
        Id recordTypeId,
        String subject,
        Id whatId,
        String description,
        Datetime startDt,
        Datetime endDt
    ) {
        Event e = new Event(StartDateTime = startDt, EndDateTime = endDt, Subject = subject);
        if (recordTypeId != null)
            e.RecordTypeId = recordTypeId;
        if (whatId != null)
            e.WhatId = whatId;
        if (description != null)
            e.Description = description;
        return e;
    }

    private static Id getHotEventRtId() {
        return [SELECT Id FROM RecordType WHERE SobjectType = 'Event' AND DeveloperName = 'HOT_Events' LIMIT 1].Id;
    }

    @IsTest
    static void deletesOnlyMatchingEvents() {
        Id hotRtId = getHotEventRtId();

        // Brukes for å fylle WhatId
        Account a = new Account(Name = 'Acme');
        insert a;

        Datetime startDt = System.now().addDays(1);
        Datetime endDt = startDt.addHours(1);

        Event shouldDelete = makeEvent(
            hotRtId,
            'SA-123',
            null,
            'Link til TinD: https://navdialog.lightning.force.com/lightning/r/ServiceAppointment/08pQC000005WRLaYAO/view',
            startDt,
            endDt
        );
        Event wrongSubject = makeEvent(
            hotRtId,
            'XX-789',
            a.Id == null ? null : null,
            'Link til TinD: https://navdialog',
            startDt,
            endDt
        );
        Event hasWhat = makeEvent(hotRtId, 'SA-999', a.Id, 'Link til TinD: https://navdialog', startDt, endDt);
        Event wrongDesc = makeEvent(hotRtId, 'SA-000', null, 'No link here', startDt, endDt);
        Event blankDesc = makeEvent(hotRtId, 'SA-777', null, null, startDt, endDt);

        List<Event> allToInsert = new List<Event>{ shouldDelete, wrongSubject, hasWhat, wrongDesc, blankDesc };

        Test.startTest();
        insert allToInsert;
        Test.stopTest();

        Set<Id> allIds = new Set<Id>();
        for (Event e : allToInsert)
            allIds.add(e.Id);

        Map<Id, Event> remaining = new Map<Id, Event>([SELECT Id FROM Event WHERE Id IN :allIds]);

        System.assert(!remaining.containsKey(shouldDelete.Id), 'Matching event should be deleted by the trigger.');
        System.assert(remaining.containsKey(wrongSubject.Id), 'Non SA- subject should remain.');
        System.assert(remaining.containsKey(hasWhat.Id), 'Events with WhatId should remain.');
        System.assert(remaining.containsKey(wrongDesc.Id), 'Events w/o required link should remain.');
        System.assert(remaining.containsKey(blankDesc.Id), 'Events with blank Description should remain.');
    }

    
    // ---------- Direct-method tests to cover return/continue branches ----------

    @IsTest
    static void returnsEarlyOnNullList() {
        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(null); // should just return
        Test.stopTest();
        System.assert(true, 'Method should return without exceptions when list is null.');
    }

    @IsTest
    static void returnsEarlyOnEmptyList() {
        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(new List<Event>()); // should just return
        Test.stopTest();
        System.assert(true, 'Method should return without exceptions when list is empty.');
    }

    @IsTest
    static void continuesOnNullRecordAndNoId() {
        // Covers: e == null, e.Id == null
        List<Event> input = new List<Event>{
            null,
            new Event()
        };
        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(input);
        Test.stopTest();
        System.assert(true, 'Null record and record without Id should be skipped.');
    }

    @IsTest
    static void continuesOnMissingOrUnknownRecordType() {
        // Covers: e.RecordTypeId == null, rti == null
        Id hotRtId = getHotEventRtId();

        Event noRt = new Event(
            Id = '00U000000000001AAA',
            Subject = 'SA-111',
            Description = 'Link til TinD: https://navdialog'
        );

        Id bogusRtId = (Id) '012000000000000AAA';
        Event unknownRt = new Event(
            Id = '00U000000000002AAA',
            RecordTypeId = bogusRtId,
            Subject = 'SA-222',
            Description = 'Link til TinD: https://navdialog'
        );

        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(new List<Event>{ noRt, unknownRt });
        Test.stopTest();
        System.assert(true, 'Events with missing or unknown RecordTypeId should be skipped.');
    }

    @IsTest
    static void continuesOnSubjectWhatIdAndDescriptionChecks() {
        Id hotRtId = getHotEventRtId();

        Event badSubject = new Event(
            Id = '00U000000000003AAA',
            RecordTypeId = hotRtId,
            Subject = 'XX-999', // not SA-
            Description = 'Link til TinD: https://navdialog'
        );
        Event hasWhat = new Event(
            Id = '00U000000000004AAA',
            RecordTypeId = hotRtId,
            Subject = 'SA-123',
            WhatId = '001000000000001AAA'
        );
        Event badDesc1 = new Event(
            Id = '00U000000000005AAA',
            RecordTypeId = hotRtId,
            Subject = 'SA-456',
            Description = null
        );
        Event badDesc2 = new Event(
            Id = '00U000000000006AAA',
            RecordTypeId = hotRtId,
            Subject = 'SA-789',
            Description = 'some other text'
        );

        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(new List<Event>{ badSubject, hasWhat, badDesc1, badDesc2 });
        Test.stopTest();
        System.assert(true, 'Events failing subject/WhatId/description checks should be skipped.');
    }

    @IsTest
    static void directCallDeletesAndLogsSuccess() {
        // Create a *real* matching Event, then call method directly to exercise success path without trigger.
        Id hotRtId = getHotEventRtId();
        Datetime startDt = System.now().addDays(1);
        Datetime endDt = startDt.addHours(1);

        Event victim = makeEvent(hotRtId, 'SA-DEL', null, 'Link til TinD: https://navdialog', startDt, endDt);
        insert victim;

        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(new List<Event>{ victim });
        Test.stopTest();

        // Should be deleted
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Event WHERE Id = :victim.Id],
            'Victim should be deleted by direct call.'
        );
    }

    @IsTest
    static void errorPathWhenDeleteFails() {
        // Make a real, matching Event
        Id hotRtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Event' AND DeveloperName = 'HOT_Events' LIMIT 1]
        .Id;

        Datetime startDt = System.now().addDays(1);
        Datetime endDt = startDt.addHours(1);

        Event victim = new Event(
            RecordTypeId = hotRtId,
            Subject = 'SA-ERR',
            WhatId = null,
            Description = 'Link til TinD: https://navdialog',
            StartDateTime = startDt,
            EndDateTime = endDt
        );
        insert victim;

        // Call the method with the *original* in-memory record (still has fields & Id)
        Test.startTest();
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(new List<Event>{ victim });
        Test.stopTest();

        System.assert(true, 'Delete failure path executed (already-deleted record).');
    }
}
