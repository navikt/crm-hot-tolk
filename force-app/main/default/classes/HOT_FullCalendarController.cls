public with sharing class HOT_FullCalendarController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getUserServiceAppointments() {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, Subject, AppointmentNumber, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE HOT_AssignedResourceId__c = :currentUserId
            ORDER BY SchedStartTime ASC
        ];

        return appointments;
    }
}
