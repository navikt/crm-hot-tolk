public without sharing class HOT_WageClaimListController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_WageClaim__c> getAvailableResources(Id recordId) {
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :recordId
        ];
        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, StartTime__c, EndTime__c, ServiceResource__r.Name, ServiceResource__c
            FROM HOT_WageClaim__c
            WHERE
                Type__c = 'Available on Wage'
                AND Status__c = 'Open'
                AND ((StartTime__c > :serviceAppointment.SchedStartTime
                AND StartTime__c < :serviceAppointment.SchedEndTime)
                OR (EndTime__c > :serviceAppointment.SchedStartTime
                AND EndTime__c < :serviceAppointment.SchedEndTime)
                OR (StartTime__c <= :serviceAppointment.SchedStartTime
                AND EndTime__c >= :serviceAppointment.SchedEndTime))
        ];
        return wageClaims;
    }
}
