public with sharing class HOT_FreelanceAbsenceController {
    public static String ERROR_RESOURCE_ABSENCE_NO_ACCESS = 'Du har ikke tilgang til fravær som er forsøkt slettet';
    public static String ERROR_RESOURCE_ABSENCE_NOT_FOUND = 'Fraværet ble ikke funnet';
    public static String ERROR_FAILED_CONFLICT_RESOLUTION = 'Kunne ikke løse konflikter. Forsøk igjen seinere, eller kontakt formidler';
    public static String ERROR_FAILED_TO_CREATE_ABSENCE = 'Kunne ikke opprette fravær. Forsøk igjen seinere, eller kontakt formidler';
    public static String ERROR_INVALID_START_AND_END_TIME = 'Sjekk at starttid kommer før sluttid';
    public static String ERROR_INVALID_ABSENCE_TYPE = 'Sjekk at type fravær er satt';
    public static STRING ERROR_FAILED_TO_DELETE_ABSENCE = 'Kunne ikke slette fravær.';

    enum ConflictingRecordType {
        SERVICE_APPOINTMENT,
        OPEN_WAGE_CLAIM
    }

    public class ConflictingRecord {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public String recordType;
        @AuraEnabled
        public String ServiceAppointmentNumber;
        @AuraEnabled
        public Datetime startTimeInMilliseconds;
        @AuraEnabled
        public Datetime endTimeInMilliseconds;
    }

    class ResolutionResult {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public Boolean resolvedSuccessfully;
        @AuraEnabled
        public String error;
    }

    @AuraEnabled
    public static Id createAbsenceAndResolveConflicts(
        Long startTimeInMilliseconds,
        Long endTimeInMilliseconds,
        String absenceType,
        Boolean isAllDayAbsence
    ) {
        if (absenceType != 'Other' && absenceType != 'Medical' && absenceType != 'Vacation') {
            prepareAndThrowAuraException(ERROR_INVALID_ABSENCE_TYPE);
        }

        if (startTimeInMilliseconds > endTimeInMilliseconds) {
            prepareAndThrowAuraException(ERROR_INVALID_START_AND_END_TIME);
        }

        Datetime startTime = Datetime.newInstance(startTimeInMilliseconds);
        Datetime endTime = Datetime.newInstance(endTimeInMilliseconds);

        if (isAllDayAbsence) {
            Date startDate = startTime.date();
            Date endDate = endTime.date();
            startTime = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
            endTime = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day());
            if (endTime != Datetime.newInstance(endTimeInMilliseconds)) {
                // om tid ikke er start på dagen, flytt end time til slutt på dagen.
                endTime = endTime.addDays(1);
            }
        }

        ResourceAbsence absence = new ResourceAbsence();
        absence.Start = startTime;
        absence.End = endTime;
        absence.ResourceId = getUserServiceResourceId();
        absence.Type = absenceType;

        try {
            resolveConflictsForTimePeriod(absence.Start, absence.End, 'Fravær');
        } catch (Exception e) {
            prepareAndThrowAuraException(ERROR_FAILED_CONFLICT_RESOLUTION);
        }

        try {
            insert absence;
        } catch (Exception e) {
            logException(e, absence);
            prepareAndThrowAuraException(ERROR_FAILED_TO_CREATE_ABSENCE);
        }

        // Maks Event lengde er 14 dager, fordi Salesforce

        Event[] events = new List<Event>();
        Date splitDate = startTime.addDays(14).date();
        Datetime splitDatetime = Datetime.newInstance(splitDate.year(), splitDate.month(), splitDate.day());
        Datetime previous = startTime;
        while (previous < endTime) {
            Datetime chunkEndTime = splitDatetime < endTime ? splitDatetime : endTime;
            events.add(createAbsenceEvent(absence.Id, previous, chunkEndTime, absenceType));
            previous = splitDatetime;
            splitDatetime = splitDatetime.addDays(14);
        }

        try {
            insert events;
        } catch (Exception e) {
            logException(e, absence);
            prepareAndThrowAuraException(ERROR_FAILED_TO_CREATE_ABSENCE);
        }

        absence.HOT_EventId__c = events[0].Id;

        try {
            update absence;
        } catch (Exception e) {
            logException(e, absence);
            prepareAndThrowAuraException(ERROR_FAILED_TO_CREATE_ABSENCE);
        }

        return absence.Id;
    }

    private static Event createAbsenceEvent(Id absenceId, Datetime startTime, Datetime endTime, String absenceType) {
        Event event = new Event();
        event.WhatId = absenceId;
        event.StartDateTime = startTime;
        event.EndDateTime = endTime;
        switch on absenceType {
            when 'Other' {
                event.Description = 'Annet';
            }
            when 'Vacation' {
                event.Description = 'Ferie';
            }
            when 'Medical' {
                event.Description = 'Sykdom.';
            }
        }
        event.Subject = 'Fravær';
        event.ShowAs = 'Busy';
        return event;
    }

    @AuraEnabled(cacheable=false)
    public static List<ConflictingRecord> getConflictsForTimePeriod(
        Long startTimeInMilliseconds,
        Long endTimeInMilliseconds,
        Boolean checkWholeDayForConflicts
    ) {
        if (startTimeInMilliseconds > endTimeInMilliseconds) {
            prepareAndThrowAuraException(ERROR_INVALID_START_AND_END_TIME);
        }

        Datetime startTime = Datetime.newInstance(startTimeInMilliseconds);
        Datetime endTime = Datetime.newInstance(endTimeInMilliseconds);

        if (checkWholeDayForConflicts) {
            Date startDate = startTime.date();
            Date endDate = endTime.date();
            startTime = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
            endTime = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day());
            endTime = endTime.addDays(1);
        }

        List<ServiceAppointment> conflictingAppointments = getConflictingServiceAppointments(startTime, endTime);

        List<HOT_WageClaim__c> conflictingOpenWageClaims = getConflictingOpenWageClaims(startTime, endTime);

        List<ConflictingRecord> conflicts = new List<ConflictingRecord>();

        for (ServiceAppointment appointment : conflictingAppointments) {
            ConflictingRecord conflict = new ConflictingRecord();
            conflict.startTimeInMilliseconds = appointment.SchedStartTime;
            conflict.endTimeInMilliseconds = appointment.SchedEndTime;
            conflict.recordId = appointment.Id;
            conflict.recordType = ConflictingRecordType.SERVICE_APPOINTMENT.toString();
            conflict.ServiceAppointmentNumber = appointment.appointmentNumber;
            conflicts.add(conflict);
        }

        for (HOT_WageClaim__c claim : conflictingOpenWageClaims) {
            ConflictingRecord conflict = new ConflictingRecord();
            conflict.startTimeInMilliseconds = claim.StartTime__c;
            conflict.endTimeInMilliseconds = claim.EndTime__c;
            conflict.recordId = claim.Id;
            conflict.recordType = ConflictingRecordType.OPEN_WAGE_CLAIM.toString();
            conflict.ServiceAppointmentNumber = claim.ServiceAppointmentName__c;
            conflicts.add(conflict);
        }

        return conflicts;
    }

    @TestVisible
    private static void resolveConflictsForTimePeriod(
        Datetime absenceStartTime,
        Datetime absenceEndTime,
        String reason
    ) {
        Id resourceId = getUserServiceResourceId();
        List<serviceAppointment> appointments = getConflictingServiceAppointments(absenceStartTime, absenceEndTime);

        HOT_HistoricallyAssignedResource__c[] historicalAssignments = new List<HOT_HistoricallyAssignedResource__c>();
        Set<Id> appointmentIds = new Set<Id>();

        for (ServiceAppointment appointment : appointments) {
            appointment.Status = 'None';
            appointment.HOT_AssignedResourceId__c = '';
            appointment.HOT_ServiceResource__c = null;
            appointment.HOT_DoNotCreateHAR__c = true;
            appointment.HOT_IsNotifyDispatcher__c = true;
            appointment.HOT_CanceledByInterpreter__c = true;

            HOT_HistoricallyAssignedResource__c har = new HOT_HistoricallyAssignedResource__c();
            har.ServiceAppointment__c = appointment.Id;
            har.ServiceResource__c = resourceId;
            har.StatusComment__c = reason;
            historicalAssignments.add(har);

            appointmentIds.add(appointment.Id);
        }

        HOT_InterestedResource__c[] interestedResources = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :resourceId AND ServiceAppointment__c IN :appointmentIds
        ];

        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            interestedResource.Status__c = 'Canceled by Interpreter';
        }

        HOT_WageClaim__c[] wageClaims = getConflictingOpenWageClaims(absenceStartTime, absenceEndTime);
        for (HOT_WageClaim__c claim : wageClaims) {
            claim.Status__c = 'Retracted Availability';
        }

        try {
            update wageClaims;
            update appointments;
            update interestedResources;
            insert historicalAssignments;
        } catch (Exception e) {
            logException(e, null);
            throw e;
        }
    }

    @TestVisible
    private static List<ServiceAppointment> getConflictingServiceAppointments(Datetime startTime, Datetime endTime) {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            WHERE
                HOT_AssignedResourceId__c = :currentUserId
                AND Status = 'Dispatched'
                AND SchedStartTime < :endTime
                AND SchedEndTime > :startTime
        ];

        return appointments;
    }

    @TestVisible
    private static List<HOT_WageClaim__c> getConflictingOpenWageClaims(Datetime startTime, Datetime endTime) {
        Id currentUserId = UserInfo.getUserId();

        Id resourceId = getUserServiceResourceId();
        return [
            SELECT Id, StartTime__c, EndTime__c, Status__c, ServiceAppointmentName__c, ServiceResource__r.Id
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__r.Id = :resourceId
                AND Status__c = 'Open'
                AND StartTime__c < :endTime
                AND EndTime__c > :startTime
        ];
    }

    @TestVisible
    private static Id getUserServiceResourceId() {
        Id currentUserId = UserInfo.getUserId();
        List<ServiceResource> resource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :currentUserId];
        return (resource.isEmpty()) ? null : resource[0].Id;
    }

    @AuraEnabled
    public static void deleteAbsence(Id recordId) {
        Id serviceResource = getUserServiceResourceId();
        ResourceAbsence[] absences = [
            SELECT Id, ResourceId
            FROM ResourceAbsence
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (absences.size() != 1) {
            prepareAndThrowAuraException(ERROR_RESOURCE_ABSENCE_NOT_FOUND);
        }

        ResourceAbsence absence = absences[0];

        if (absence.ResourceId != serviceResource) {
            LoggerUtility logger = new LoggerUtility();
            String logMessage =
                'ResourceAbsence ' +
                recordId +
                ' was attempted deleted by user' +
                UserInfo.getUserId() +
                ' without access to record';
            logger.warning(logMessage, absence, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
            prepareAndThrowAuraException(ERROR_RESOURCE_ABSENCE_NO_ACCESS);
        }

        Event[] relatedEvents = [SELECT Id FROM Event WHERE WhatId = :absence.Id];

        try {
            delete relatedEvents;
            delete absence;
        } catch (Exception e) {
            logException(e, absence);
            prepareAndThrowAuraException(ERROR_FAILED_TO_DELETE_ABSENCE);
        }
    }

    private static void prepareAndThrowAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        throw e;
    }

    @TestVisible
    private static Boolean logException(Exception exceptionToLog, SObject relatedRecord) {
        try {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(exceptionToLog, relatedRecord, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        } catch (Exception e) {
            return false;
        }
        return true;
    }
}
