public with sharing class HOT_FreelanceAbsenceController {
    enum ConflictingRecordType {
        SERVICE_APPOINTMENT,
        OPEN_WAGE_CLAIM
    }

    class ConflictingRecord {
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
    public static void createAbsenceAndResolveConflicts(
        Long startTimeInMilliseconds,
        Long endTimeInMilliseconds,
        String absenceType
    ) {
        if (absenceType != 'Other' && absenceType != 'Medical' && absenceType != 'Vacation') {
            throw new IllegalArgumentException('Not a valid absence type');
        }
        ResourceAbsence absence = new ResourceAbsence();
        absence.Start = Datetime.newInstance(startTimeInMilliseconds);
        absence.End = Datetime.newInstance(endTimeInMilliseconds);
        absence.ResourceId = getUserServiceResourceId();
        absence.Type = absenceType;

        ConflictingRecord[] conflictingRecords = getConflictsForTimePeriod(
            startTimeInMilliseconds,
            endTimeInMilliseconds
        );
        resolveConflictsForTimePeriod(absence.Start, absence.End, 'Fravær');

        insert absence;
    }

    @AuraEnabled(cacheable=false)
    public static List<ConflictingRecord> getConflictsForTimePeriod(
        Long startTimeInMilliseconds,
        Long endTimeInMilliseconds
    ) {
        Datetime startTime = Datetime.newInstance(startTimeInMilliseconds);
        Datetime endTime = Datetime.newInstance(endTimeInMilliseconds);

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

        HOT_InterestedResource__c[] interestedResources = new List<HOT_InterestedResource__c>();
        HOT_HistoricallyAssignedResource__c[] historicalAssignments = new List<HOT_HistoricallyAssignedResource__c>();
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = null;
            appointment.HOT_AssignedResourceId__c = '';
            appointment.HOT_DoNotCreateHAR__c = true;
            appointment.HOT_IsNotifyDispatcher__c = true;
            appointment.HOT_CanceledByInterpreter__c = true;

            HOT_HistoricallyAssignedResource__c har = new HOT_HistoricallyAssignedResource__c();
            har.ServiceAppointment__c = appointment.Id;
            har.ServiceResource__c = resourceId;
            har.StatusComment__c = reason;
            historicalAssignments.add(har);

            HOT_InterestedResource__c[] interestedResource = [
                SELECT Id
                FROM HOT_InterestedResource__c
                WHERE ServiceResource__c = :resourceId AND ServiceAppointment__c = :appointment.id
                LIMIT 1
            ];

            if (!interestedResource.isEmpty()) {
                interestedResource[0].Status__c = 'Canceled by Interpreter';
                interestedResources.add(interestedResource[0]);
            }
        }

        HOT_WageClaim__c[] wageClaims = getConflictingOpenWageClaims(absenceStartTime, absenceEndTime);
        for (HOT_WageClaim__c claim : wageClaims) {
            claim.Status__c = 'Retracted Availability';
        }

        update wageClaims;
        update appointments;
        update interestedResources;
        insert historicalAssignments;
    }

    @TestVisible
    private static List<ServiceAppointment> getConflictingServiceAppointments(Datetime startTime, Datetime endTime) {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            WHERE
                HOT_AssignedResourceId__c = :currentUserId
                AND SchedStartTime < :endTime
                AND SchedEndTime > :startTime
                AND Status = 'Dispatched'
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
        ResourceAbsence absence = [
            SELECT Id
            FROM ResourceAbsence
            WHERE Id = :recordId AND ResourceId = :serviceResource
            LIMIT 1
        ];
        delete absence;
    }
}
