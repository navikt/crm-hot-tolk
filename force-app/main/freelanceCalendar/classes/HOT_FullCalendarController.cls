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
        public String description;
        @AuraEnabled
        public DateTime startTime;
        @AuraEnabled
        public DateTime endTime;
        @AuraEnabled
        public String appointmentNumber;
    }

    @AuraEnabled(cacheable=true)
    public static List<CalendarEvent> getCalendarEvents(
        Long earliestEventEndTimeInMilliseconds,
        Long latestEventStartInMilliseconds
    ) {
        List<CalendarEvent> events = new List<CalendarEvent>();

        DateTime earliestTime = DateTime.newInstance(earliestEventEndTimeInMilliseconds);
        DateTime latestTime = DateTime.newInstance(latestEventStartInMilliseconds);

        List<ServiceAppointment> appointments = getUserServiceAppointments(earliestTime, latestTime);
        List<HOT_WageClaim__c> openWageClaims = getUserOpenWageClaims(earliestTime, latestTime);

        for (ServiceAppointment appointment : appointments) {
            CalendarEvent event = new CalendarEvent();
            event.id = appointment.Id;
            event.appointmentNumber = appointment.AppointmentNumber;
            event.type = (appointment.Status == 'Dispatched')
                ? EventType.SERVICE_APPOINTMENT.toString()
                : EventType.COMPLETED_SERVICE_APPOINTMENT.toString();
            event.startTime = appointment.SchedStartTime;
            event.endTime = appointment.SchedEndTime;
            event.description = appointment.Subject;
            events.add(event);
        }

        for (HOT_WageClaim__c claim : openWageClaims) {
            CalendarEvent event = new CalendarEvent();
            event.id = claim.Id;
            event.appointmentNumber = claim.ServiceAppointmentName__c;
            event.type = EventType.OPEN_WAGE_CLAIM.toString();
            event.startTime = claim.StartTime__c;
            event.endTime = claim.EndTime__c;
            event.description = 'Ledig på lønn';
            events.add(event);
        }
        return events;
    }

    @TestVisible
    private static List<ServiceAppointment> getUserServiceAppointments(
        DateTime earliestAppointmentEnd,
        DateTime latestAppointmentStart
    ) {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, Subject, AppointmentNumber, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            WHERE
                HOT_AssignedResourceId__c = :currentUserId
                AND SchedEndTime > :earliestAppointmentEnd
                AND SchedStartTime < :latestAppointmentStart
                AND (Status = 'Dispatched'
                OR Status = 'Completed')
            ORDER BY SchedStartTime ASC
        ];

        return appointments;
    }

    @TestVisible
    private static List<HOT_WageClaim__c> getUserOpenWageClaims(
        DateTime earliestWageClaimEnd,
        DateTime latestWageClaimStart
    ) {
        Id resourceId = getUserServiceResourceId();
        return [
            SELECT Id, StartTime__c, EndTime__c, ServiceResource__r.Id, Status__c, ServiceAppointmentName__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__r.Id = :resourceId
                AND Status__c = 'Open'
                AND EndTime__c > :earliestWageClaimEnd
                AND StartTime__c < :latestWageClaimStart
        ];
    }

    @TestVisible
    private static Id getUserServiceResourceId() {
        Id currentUserId = UserInfo.getUserId();
        List<ServiceResource> resource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :currentUserId];
        return (resource.isEmpty()) ? null : resource[0].Id;
    }
}
