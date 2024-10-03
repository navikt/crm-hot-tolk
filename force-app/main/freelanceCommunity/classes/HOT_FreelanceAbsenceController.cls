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
    public static Boolean createServiceResourceAbsence(
        Integer startTimeInMilliseconds,
        Integer endTimeInMilliseconds,
        String absenceType
    ) {
        return false;
    }

    @AuraEnabled(cacheable=true)
    public static List<ConflictingRecord> getConflictsForTimePeriod(
        Integer startTimeInMilliseconds,
        Integer endTimeInMilliseconds
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

    @AuraEnabled
    public static List<ResolutionResult> resolveAbsenceConflicts(List<ConflictingRecord> conflicts, String reason) {
        Set<Id> appointmentIds = new Set<Id>();
        Set<Id> wageClaimIds = new Set<Id>();

        List<ResolutionResult> results = new List<ResolutionResult>();

        for (ConflictingRecord conflict : conflicts) {
            if (conflict.recordType == ConflictingRecordType.OPEN_WAGE_CLAIM) {
                wageClaimIds.add(conflict.recordId);
            } else {
                appointmentIds.add(conflict.recordId);
            }
        }

        Id currentUserId = UserInfo.getUserId();
        Id resourceId = getUserServiceResourceId();
        List<ServiceAppointment> appointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_AssignedResourceId__c = :currentUserId AND Id IN :appointmentIds.keySet()
        ];

        HOT_InterestedResource__c[] interestedResources = new List<HOT_InterestedResource__c>();
        HOT_HistoricallyAssignedResource__c[] historicalAssignments = new List<HOT_HistoricallyAssignedResource__c>();
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = null;
            appointment.HOT_AssignedResourceId__c = '';
            appointment.ServiceResource = '';
            appointment.HOT_DoNotCreateHAR__c = true;
            appointment.HOT_IsNotifyDispatcher__c = true;
            appointment.HOT_CanceledByInterpreter__c = true;

            HOT_HistoricallyAssignedResource__c har = new HOT_HistoricallyAssignedResource();
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

            if(!interestedResource.isEmpty()) {
                interestedResource[0].Status__c = 'Canceled by Interpreter';
                interestedResources.add(ir[0]);
            }
        }

        update interestedResources;
        insert historicalAssignments;

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceResource__r.Id
            FROM HOT_WageClaim__c
            WHERE ServiceResource__r.Id = :resourceId AND Id IN :wageClaimIds
        ];

        for (HOT_WageClaim__c claim : wageClaims) {
            claim.Status__c = 'Retracted Availability';
        }

        
        Database.SaveResult[] wageClaimUpdateResults = Database.update(wageClaims, false);
        Database.SaveResult[] appointmentUpdateResults = Database.update(appointments, false);
    }

    @TestVisible
    private static List<ServiceAppointment> getConflictingServiceAppointments(Datetime startTime, Datetime endTime) {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            WHERE
                HOT_AssignedResourceId__c = :currentUserId
                AND SchedStartTime >= :startTime
                AND SchedEndTime <= :endTime
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
                AND StartTime__c >= :startTime
                AND EndTime__c <= :endTime
        ];
    }

    @TestVisible
    private static Id getUserServiceResourceId() {
        Id currentUserId = UserInfo.getUserId();
        List<ServiceResource> resource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :currentUserId];
        return (resource.isEmpty()) ? null : resource[0].Id;
    }
}