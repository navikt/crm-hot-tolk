public with sharing class HOT_FullCalendarController {
    public enum EventType {
        COMPLETED_SERVICE_APPOINTMENT,
        SERVICE_APPOINTMENT,
        OPEN_WAGE_CLAIM
    }

    public class CalendarEvent {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public DateTime startTime;
        @AuraEnabled
        public DateTime endTime;
    }

    @AuraEnabled(cacheable=true)
    public static List<CalendarEvent> getCalendarEvents(
        Long earliestTimeInMilliseconds,
        Long latestTimeInMilliseconds
    ) {
        List<CalendarEvent> events = new List<CalendarEvent>();

        DateTime earliestTime = DateTime.newInstance(earliestTimeInMilliseconds);
        DateTime latestTime = DateTime.newInstance(latestTimeInMilliseconds);

        List<ServiceAppointment> appointments = getUserServiceAppointments(earliestTime, latestTime);
        List<HOT_WageClaim__c> openWageClaims = getUserOpenWageClaims(earliestTime, latestTime);

        for (ServiceAppointment appointment : appointments) {
            CalendarEvent event = new CalendarEvent();
            event.id = appointment.Id;
            event.type = EventType.SERVICE_APPOINTMENT.toString();
            event.startTime = appointment.SchedStartTime;
            event.endTime = appointment.SchedEndTime;
            event.title = appointment.Subject;
            events.add(event);
        }

        for (HOT_WageClaim__c claim : openWageClaims) {
            CalendarEvent event = new CalendarEvent();
            event.id = claim.Id;
            event.type = EventType.OPEN_WAGE_CLAIM.toString();
            event.startTime = claim.StartTime__c;
            event.endTime = claim.EndTime__c;
            event.title = 'Ledig på lønn';
            events.add(event);
        }
        return events;
    }

    @TestVisible
    private static List<ServiceAppointment> getUserServiceAppointments(DateTime earliestTime, DateTime latestTime) {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, Subject, AppointmentNumber, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE
                HOT_AssignedResourceId__c = :currentUserId
                AND SchedEndTime < :latestTime
                AND SchedStartTime > :earliestTime
            ORDER BY SchedStartTime ASC
        ];

        return appointments;
    }

    @TestVisible
    private static List<HOT_WageClaim__c> getUserOpenWageClaims(DateTime earliestTime, DateTime latestTime) {
        Id resourceId = getUserServiceResourceId();
        return [
            SELECT Id, StartTime__c, EndTime__c, ServiceResource__r.Id, Status__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__r.Id = :resourceId
                AND Status__c = 'Open'
                AND EndTime__c < :latestTime
                AND StartTime__c > :earliestTime
        ];
    }

    @TestVisible
    private static Id getUserServiceResourceId() {
        Id currentUserId = UserInfo.getUserId();
        List<ServiceResource> resource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :currentUserId];
        return (resource.isEmpty()) ? null : resource[0].Id;
    }
}
