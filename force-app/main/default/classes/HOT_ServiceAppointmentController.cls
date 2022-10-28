public without sharing class HOT_ServiceAppointmentController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String recordId) {
        HOT_InterestedResource__c interestedResource = [
            SELECT ServiceAppointment__c, ServiceAppointment__r.ServiceTerritoryId, ServiceAppointment__r.WorkTypeId
            FROM HOT_InterestedResource__c
            WHERE Id = :recordId
        ];
        List<ServiceAppointment> ServiceAppointments = [
            SELECT
                Id,
                AppointmentNumber,
                SchedStartTime,
                SchedEndTime,
                HOT_WorkTypeName__c,
                HOT_ServiceTerritoryName__c,
                Status,
                HOT_AssignmentType__c
            FROM ServiceAppointment
            WHERE
                (Status = 'None'
                OR Status = 'Released to Freelance')
                AND Id != :interestedResource.ServiceAppointment__c
                AND ServiceTerritoryId = :interestedResource.ServiceAppointment__r.ServiceTerritoryId
                AND WorkTypeId = :interestedResource.ServiceAppointment__r.WorkTypeId
        ];
        return ServiceAppointments;
    }
}
