public with sharing class HOT_InterestedResourceBannerController {
    @AuraEnabled
    public static List<ServiceAppointment> checkForOverlap(String recordId){
        HOT_InterestedResource__c interestedResource=[SELECT ServiceResource__c,ServiceAppointmentStartTime__c, ServiceAppointmentEndTime__c FROM HOT_InterestedResource__c WHERE Id=:recordId LIMIT 1];

        List<ServiceAppointment> serviceAppointments=[SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id IN(SELECT ServiceAppointmentId FROM AssignedResource  WHERE ServiceResourceId=:interestedResource.ServiceResource__c) AND (SchedStartTime <= :interestedResource.ServiceAppointmentEndTime__c) AND (SchedEndTime >= :interestedResource.ServiceAppointmentStartTime__c)];
       
       return serviceAppointments;
    }
}
