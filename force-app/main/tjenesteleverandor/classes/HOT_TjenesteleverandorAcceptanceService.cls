public without sharing class HOT_TjenesteleverandorAcceptanceService {
    private static final String ACCEPT_PERMISSION = 'HOT_AcceptTjenesteleverandorOppdrag';
    private static final String DECLINE_PERMISSION = 'HOT_DeclineTjenesteleverandorOppdrag';
    private static final Integer MAX_APPOINTMENTS_PER_REQUEST = 200;
    private static final String STATUS_ACCEPTED = 'Accepted';
    private static final String STATUS_DECLINED = 'Declined';
    private static final String STATUS_TRANSFERRED = 'Transferred';
    private static final String SALESFORCE_STATUS_RELEASED = 'Released to Freelance';

    private enum SupplierResponse {
        ACCEPT,
        DECLINE
    }

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
        assertPermission(SupplierResponse.ACCEPT);
        return respondToServiceAppointments(serviceAppointmentIds, SupplierResponse.ACCEPT);
    }

    @AuraEnabled
    public static List<AcceptanceResult> declineServiceAppointments(List<Id> serviceAppointmentIds) {
        assertPermission(SupplierResponse.DECLINE);
        return respondToServiceAppointments(serviceAppointmentIds, SupplierResponse.DECLINE);
    }

    private static List<AcceptanceResult> respondToServiceAppointments(
        List<Id> serviceAppointmentIds,
        SupplierResponse response
    ) {
        List<Id> requestedIds = normalizeIds(serviceAppointmentIds, response);
        Map<Id, ServiceAppointment> appointmentById = lockAppointments(new Set<Id>(requestedIds));
        List<AcceptanceResult> results = new List<AcceptanceResult>();
        List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
        List<AcceptanceResult> updateResults = new List<AcceptanceResult>();
        Datetime currentTime = System.now();
        String targetStatus = response == SupplierResponse.ACCEPT ? STATUS_ACCEPTED : STATUS_DECLINED;

        for (Id requestedId : requestedIds) {
            AcceptanceResult result = new AcceptanceResult(requestedId);
            results.add(result);
            ServiceAppointment appointment = appointmentById.get(requestedId);

            if (appointment == null) {
                result.message = 'Du har ikke tilgang til oppdraget, eller oppdraget finnes ikke.';
                continue;
            }
            if (appointment.HOT_TjenesteleverandorStatus__c == targetStatus) {
                result.success = true;
                result.message = response == SupplierResponse.ACCEPT
                    ? 'Oppdraget er allerede akseptert.'
                    : 'Oppdraget er allerede avslått.';
                continue;
            }

            String responseError = getResponseError(appointment, currentTime, response);
            if (responseError != null) {
                result.message = responseError;
                continue;
            }

            appointment.HOT_TjenesteleverandorStatus__c = targetStatus;
            appointmentsToUpdate.add(appointment);
            updateResults.add(result);
        }

        if (!appointmentsToUpdate.isEmpty()) {
            // The external user remains read-only. This narrowly scoped system-mode DML can only set the supplier status.
            Database.SaveResult[] saveResults = Database.update(appointmentsToUpdate, false, AccessLevel.SYSTEM_MODE);
            applySaveResults(saveResults, updateResults, response);
        }

        return results;
    }

    private static void assertPermission(SupplierResponse response) {
        String permissionName = response == SupplierResponse.ACCEPT ? ACCEPT_PERMISSION : DECLINE_PERMISSION;
        if (!permissionHelper.hasCustomPermission(permissionName)) {
            String message = response == SupplierResponse.ACCEPT
                ? 'Du har ikke tilgang til å akseptere oppdrag.'
                : 'Du har ikke tilgang til å avslå oppdrag.';
            throw new AuraHandledException(message);
        }
    }

    private static List<Id> normalizeIds(List<Id> serviceAppointmentIds, SupplierResponse response) {
        String action = response == SupplierResponse.ACCEPT ? 'aksepteres' : 'avslås';
        if (serviceAppointmentIds == null || serviceAppointmentIds.isEmpty()) {
            throw new AuraHandledException('Velg minst ett oppdrag som skal ' + action + '.');
        }

        List<Id> normalizedIds = new List<Id>();
        Set<Id> uniqueIds = new Set<Id>();
        for (Id serviceAppointmentId : serviceAppointmentIds) {
            if (serviceAppointmentId != null && uniqueIds.add(serviceAppointmentId)) {
                normalizedIds.add(serviceAppointmentId);
            }
        }

        if (normalizedIds.isEmpty()) {
            throw new AuraHandledException('Velg minst ett oppdrag som skal ' + action + '.');
        }
        if (normalizedIds.size() > MAX_APPOINTMENTS_PER_REQUEST) {
            String infinitive = response == SupplierResponse.ACCEPT ? 'akseptere' : 'avslå';
            throw new AuraHandledException('Du kan ' + infinitive + ' maksimalt 200 oppdrag om gangen.');
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

    private static String getResponseError(
        ServiceAppointment appointment,
        Datetime currentTime,
        SupplierResponse response
    ) {
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
            return 'Svarfristen for oppdraget har utløpt.';
        }
        return response == SupplierResponse.ACCEPT
            ? 'Oppdraget kan ikke aksepteres lenger. Last inn siden på nytt.'
            : 'Oppdraget kan ikke avslås lenger. Last inn siden på nytt.';
    }

    private static void applySaveResults(
        Database.SaveResult[] saveResults,
        List<AcceptanceResult> acceptanceResults,
        SupplierResponse response
    ) {
        for (Integer index = 0; index < saveResults.size(); index++) {
            AcceptanceResult result = acceptanceResults[index];
            if (saveResults[index].isSuccess()) {
                result.success = true;
                result.message = response == SupplierResponse.ACCEPT
                    ? 'Oppdraget er akseptert.'
                    : 'Oppdraget er avslått.';
            } else {
                result.message = response == SupplierResponse.ACCEPT
                    ? 'Oppdraget kunne ikke aksepteres. Last inn siden og prøv igjen.'
                    : 'Oppdraget kunne ikke avslås. Last inn siden og prøv igjen.';
            }
        }
    }
}
