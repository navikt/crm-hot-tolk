public without sharing class HOT_ServiceAppointmentWageClaim {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String wageClaimId) {
        HOT_WageClaim__c wageClaim = [
            SELECT Id, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaimId
            LIMIT 1
        ];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, SchedStartTime, SchedEndTime, HOT_WorkTypeName__c, Status
            FROM ServiceAppointment
            //WHERE SchedStartTime > :wageClaim.StartTime__c AND SchedStartTime < :wageClaim.EndTime__c
        ];

        return serviceAppointments;
    }
}
