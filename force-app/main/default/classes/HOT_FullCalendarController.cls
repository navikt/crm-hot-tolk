public with sharing class HOT_FullCalendarController {
    @AuraEnabled(cacheable=true)
    public static List<EventDTO> getUserServiceAppointments() {
        Id currentUserId = UserInfo.getUserId();

        List<ServiceAppointment> appointments = [
            SELECT Id, Subject, AppointmentNumber, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE HOT_AssignedResourceId__c = :currentUserId
            ORDER BY SchedStartTime ASC
        ];

        List<EventDTO> events = new List<EventDTO>();
        for (ServiceAppointment appointment : appointments) {
            events.add(new EventDTO(appointment.Subject, appointment.SchedStartTime));
        }

        return events;
    }

    // DTO to pass the necessary event data to the LWC
    public class EventDTO {
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String start { get; set; }

        public EventDTO(String title, DateTime startDate) {
            this.title = title;
            this.start = startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); // FullCalendar expects ISO 8601 format
        }
    }
}
