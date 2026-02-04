public without sharing class HOT_LateCancellationListController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getLateCancellationsForUser() {
        Id accountId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;

        if (accountId == null) {
            return new List<ServiceAppointment>();
        }

        List<HOT_HistoricallyAssignedResource__c> historicRows = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, CreatedDate
            FROM HOT_HistoricallyAssignedResource__c
            WHERE
                ServiceAppointment__r.HOT_LateCancellation__c = TRUE
                AND ServiceResource__r.AccountId = :accountId
                AND Status__c IN ('Tolk tatt av oppdraget', 'Avlyst av bruker')
            ORDER BY ServiceAppointment__c, CreatedDate DESC
        ];

        if (historicRows.isEmpty()) {
            return new List<ServiceAppointment>();
        }

        Map<Id, HOT_HistoricallyAssignedResource__c> lastHistoricBySa = new Map<Id, HOT_HistoricallyAssignedResource__c>();

        for (HOT_HistoricallyAssignedResource__c har : historicRows) {
            if (!lastHistoricBySa.containsKey(har.ServiceAppointment__c)) {
                lastHistoricBySa.put(har.ServiceAppointment__c, har);
            }
        }

        Set<Id> validServiceAppointmentIds = new Set<Id>();

        for (HOT_InterestedResource__c ir : [
            SELECT ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :lastHistoricBySa.keySet() AND Status__c = 'Canceled'
        ]) {
            HOT_HistoricallyAssignedResource__c lastHar = lastHistoricBySa.get(ir.ServiceAppointment__c);

            if (lastHar != null && ir.ServiceResource__c == lastHar.ServiceResource__c) {
                validServiceAppointmentIds.add(ir.ServiceAppointment__c);
            }
        }

        if (validServiceAppointmentIds.isEmpty()) {
            return new List<ServiceAppointment>();
        }

        return [
            SELECT
                Id,
                AppointmentNumber,
                Subject,
                toLabel(Status),
                EarliestStartTime,
                DueDate,
                SchedStartTime,
                SchedEndTime,
                HOT_InterpretationPostalCity__c,
                HOT_WorkTypeName__c,
                HOT_AssignmentType__c,
                HOT_Request__r.OwnerName__c,
                HOT_DegreeOfHearingAndVisualImpairment__c
            FROM ServiceAppointment
            WHERE Id IN :validServiceAppointmentIds
            ORDER BY EarliestStartTime DESC
        ];
    }
}
