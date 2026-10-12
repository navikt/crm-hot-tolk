public without sharing class HOT_TjenesteleverandorAcceptanceService {
    private static final String ACCEPT_PERMISSION = 'HOT_AcceptTjenesteleverandorOppdrag';
    private static final Integer MAX_APPOINTMENTS_PER_REQUEST = 200;
    private static final String STATUS_ACCEPTED = 'Accepted';
    private static final String STATUS_TRANSFERRED = 'Transferred';
    private static final String SALESFORCE_STATUS_RELEASED = 'Released to Freelance';

    @TestVisible
    private static CustomPermissionHelper permissionHelper = new CustomPermissionHelper();

    public class AcceptanceResult {
        @AuraEnabled
        public Id recordId { get; set; }

        @AuraEnabled
        public Boolean success { get; set; }

        @AuraEnabled
        public String message { get; set; }

        private AcceptanceResult(Id recordId) {
            this.recordId = recordId;
            this.success = false;
        }
    }

    @AuraEnabled
    public static List<AcceptanceResult> acceptServiceAppointments(List<Id> serviceAppointmentIds) {
        assertPermission();
        List<Id> requestedIds = normalizeIds(serviceAppointmentIds);
        Map<Id, ServiceAppointment> appointmentById = lockAppointments(new Set<Id>(requestedIds));
        List<AcceptanceResult> results = new List<AcceptanceResult>();
        List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
        List<AcceptanceResult> updateResults = new List<AcceptanceResult>();
        Datetime currentTime = System.now();

        for (Id requestedId : requestedIds) {
            AcceptanceResult result = new AcceptanceResult(requestedId);
            results.add(result);
            ServiceAppointment appointment = appointmentById.get(requestedId);

            if (appointment == null) {
                result.message = 'Du har ikke tilgang til oppdraget, eller oppdraget finnes ikke.';
                continue;
            }
            if (appointment.HOT_TjenesteleverandorStatus__c == STATUS_ACCEPTED) {
                result.success = true;
                result.message = 'Oppdraget er allerede bekreftet.';
                continue;
            }

            String confirmationError = getConfirmationError(appointment, currentTime);
            if (confirmationError != null) {
                result.message = confirmationError;
                continue;
            }

            appointment.HOT_TjenesteleverandorStatus__c = STATUS_ACCEPTED;
            appointment.HOT_TLDispatcher__c = UserInfo.getUserId();
            appointmentsToUpdate.add(appointment);
            updateResults.add(result);
        }

        if (!appointmentsToUpdate.isEmpty()) {
            // The external user remains read-only. Only confirmation and its dispatcher stamp use elevated DML.
            Database.SaveResult[] saveResults = Database.update(appointmentsToUpdate, false, AccessLevel.SYSTEM_MODE);
            applySaveResults(saveResults, updateResults);
        }

        return results;
    }

    private static void assertPermission() {
        if (!permissionHelper.hasCustomPermission(ACCEPT_PERMISSION)) {
            throw new AuraHandledException('Du har ikke tilgang til å bekrefte oppdrag.');
        }
    }

    private static List<Id> normalizeIds(List<Id> serviceAppointmentIds) {
        if (serviceAppointmentIds == null || serviceAppointmentIds.isEmpty()) {
            throw new AuraHandledException('Velg minst ett oppdrag som skal bekreftes.');
        }

        List<Id> normalizedIds = new List<Id>();
        Set<Id> uniqueIds = new Set<Id>();
        for (Id serviceAppointmentId : serviceAppointmentIds) {
            if (serviceAppointmentId != null && uniqueIds.add(serviceAppointmentId)) {
                normalizedIds.add(serviceAppointmentId);
            }
        }

        if (normalizedIds.isEmpty()) {
            throw new AuraHandledException('Velg minst ett oppdrag som skal bekreftes.');
        }
        if (normalizedIds.size() > MAX_APPOINTMENTS_PER_REQUEST) {
            throw new AuraHandledException('Du kan bekrefte maksimalt 200 oppdrag om gangen.');
        }
        return normalizedIds;
    }

    private static Map<Id, ServiceAppointment> lockAppointments(Set<Id> requestedIds) {
        return new Map<Id, ServiceAppointment>(
            [
                SELECT
                    Id,
                    Status,
                    HOT_IsReleasedToFreelance__c,
                    HOT_TjenesteleverandorStatus__c,
                    HOT_TjenesteleverandorDeadline__c
                FROM ServiceAppointment
                WHERE Id IN :requestedIds
                WITH USER_MODE
                FOR UPDATE
            ]
        );
    }

    private static String getConfirmationError(ServiceAppointment appointment, Datetime currentTime) {
        Boolean isEligible =
            appointment.HOT_TjenesteleverandorStatus__c == STATUS_TRANSFERRED &&
            appointment.Status == SALESFORCE_STATUS_RELEASED &&
            appointment.HOT_IsReleasedToFreelance__c == true &&
            appointment.HOT_TjenesteleverandorDeadline__c != null &&
            appointment.HOT_TjenesteleverandorDeadline__c > currentTime;
        if (isEligible) {
            return null;
        }
        if (
            appointment.HOT_TjenesteleverandorDeadline__c != null &&
            appointment.HOT_TjenesteleverandorDeadline__c <= currentTime
        ) {
            return 'Bekreftelsesfristen for oppdraget har utløpt.';
        }
        return 'Oppdraget kan ikke bekreftes lenger. Last inn siden på nytt.';
    }

    private static void applySaveResults(Database.SaveResult[] saveResults, List<AcceptanceResult> acceptanceResults) {
        for (Integer index = 0; index < saveResults.size(); index++) {
            AcceptanceResult result = acceptanceResults[index];
            if (saveResults[index].isSuccess()) {
                result.success = true;
                result.message = 'Oppdraget er bekreftet.';
            } else {
                result.message = 'Oppdraget kunne ikke bekreftes. Last inn siden og prøv igjen.';
            }
        }
    }
}
