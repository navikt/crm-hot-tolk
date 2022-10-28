public without sharing class HOT_ServiceAppointmentController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String recordId) {
        HOT_InterestedResource__c interestedResource=[SELECT ServiceAppointment__c FROM HOT_InterestedResource__c WHERE Id=:recordId];
        List<ServiceAppointment> ServiceAppointments = [
            SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, HOT_WorkTypeName__c, HOT_ServiceTerritoryName__c, Status, HOT_AssignmentType__c
            FROM ServiceAppointment WHERE (Status='None' OR Status='Released to Freelance') AND (Id!=:interestedResource.ServiceAppointment__c)
        ];
        return ServiceAppointments;
    }
}
