public with sharing class HOT_LateCancellationListController {
   

//         @AuraEnabled(cacheable=true)
// public static List<ServiceAppointment> getLateCancellationsForUser() {

//     Id currentUserAccountId = [
//         SELECT AccountId
//         FROM User
//         WHERE Id = :UserInfo.getUserId()
//     ].AccountId;

//     if (currentUserAccountId == null) {
//         return new List<ServiceAppointment>();
//     }

//     List<HOT_HistoricallyAssignedResource__c> latestHistoricResources = [
//         SELECT Id,
//                ServiceAppointment__c,
//                ServiceResource__c,
//                CreatedDate
//         FROM HOT_HistoricallyAssignedResource__c
//         WHERE
//             ServiceAppointment__r.HOT_LateCancellation__c = TRUE
//             AND ServiceResource__r.AccountId = :currentUserAccountId
//             AND Status__c IN ('Tolk tatt av oppdraget', 'Avlyst av bruker')
//         ORDER BY ServiceAppointment__c, CreatedDate DESC
//     ];

//     if (latestHistoricResources.isEmpty()) {
//         return new List<ServiceAppointment>();
//     }

//     Map<Id, HOT_HistoricallyAssignedResource__c> lastHistoricBySA = new Map<Id, HOT_HistoricallyAssignedResource__c>();

//     for (HOT_HistoricallyAssignedResource__c har : latestHistoricResources) {
//         if (!lastHistoricBySA.containsKey(har.ServiceAppointment__c)) {
//             lastHistoricBySA.put(har.ServiceAppointment__c, har);
//         }
//     }

//     Set<Id> matchingServiceAppointmentIds = new Set<Id>();

//     for (AggregateResult ar : [
//         SELECT ServiceAppointment__c saId
//         FROM HOT_InterestedResource__c
//         WHERE
//             ServiceAppointment__c IN :lastHistoricBySA.keySet()
//             AND Status__c != 'Reserved'
//         GROUP BY ServiceAppointment__c
//     ]) {
//         matchingServiceAppointmentIds.add((Id) ar.get('saId'));
//     }

//     if (matchingServiceAppointmentIds.isEmpty()) {
//         return new List<ServiceAppointment>();
//     }

//     return [
//         SELECT Id,
//                AppointmentNumber,
//                Subject,
//                Status,
//                EarliestStartTime,
//                DueDate,
//                SchedStartTime,
//                SchedEndTime,
//                HOT_InterpretationPostalCity__c,
//                HOT_WorkTypeName__c,
//                HOT_AssignmentType__c,
//                HOT_Request__r.OwnerName__c,
//                HOT_DegreeOfHearingAndVisualImpairment__c
//         FROM ServiceAppointment
//         WHERE Id IN :matchingServiceAppointmentIds
//     ];
// }



    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getLateCancellationsForUser() {

        Id accountId = [
            SELECT AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].AccountId;

        if (accountId == null) {
            return new List<ServiceAppointment>();
        }

        List<HOT_HistoricallyAssignedResource__c> historicRows = [
            SELECT Id,
                   ServiceAppointment__c,
                   ServiceResource__c,
                   CreatedDate
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

        // siste historic per SA
        Map<Id, HOT_HistoricallyAssignedResource__c> lastHistoricBySa =
            new Map<Id, HOT_HistoricallyAssignedResource__c>();

        for (HOT_HistoricallyAssignedResource__c har : historicRows) {
            if (!lastHistoricBySa.containsKey(har.ServiceAppointment__c)) {
                lastHistoricBySa.put(har.ServiceAppointment__c, har);
            }
        }

        Set<Id> validServiceAppointmentIds = new Set<Id>();

        for (HOT_InterestedResource__c ir : [
            SELECT ServiceAppointment__c,
                   ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceAppointment__c IN :lastHistoricBySa.keySet()
                AND Status__c != 'Reserved'
        ]) {
            HOT_HistoricallyAssignedResource__c lastHar =
                lastHistoricBySa.get(ir.ServiceAppointment__c);

            if (lastHar != null &&
                ir.ServiceResource__c == lastHar.ServiceResource__c) {

                validServiceAppointmentIds.add(ir.ServiceAppointment__c);
            }
        }

        if (validServiceAppointmentIds.isEmpty()) {
            return new List<ServiceAppointment>();
        }

        return [
            SELECT Id,
                   AppointmentNumber,
                   Subject,
                   Status,
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
        ];
    }


}


    
