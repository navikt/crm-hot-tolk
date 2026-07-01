public with sharing class HOT_FullCalendarController {
    public enum EventType {
        OPEN_SERVICE_APPOINTMENT,
        COMPLETED_SERVICE_APPOINTMENT,
        SERVICE_APPOINTMENT,
        OPEN_WAGE_CLAIM,
        WAGE_CLAIM_NEW_TYPE,
        RESOURCE_ABSENCE
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

    private without sharing class OpenServiceAppointmentSelector {
        List<ServiceAppointment> getOpenServiceAppointments(
            DateTime earliestAppointmentEnd,
            DateTime latestAppointmentStart
        ) {
            Id userId = UserInfo.getUserId();

            List<ServiceResource> serviceResources = [
                SELECT Id, HOT_PreferredRegions__c, HOT_ShowOpenServiceAppointmentEvents__c
                FROM ServiceResource
                WHERE RelatedRecordId = :userId
                LIMIT 1
            ];

            if (serviceResources.isEmpty() || serviceResources[0].HOT_ShowOpenServiceAppointmentEvents__c != true) {
                return new List<ServiceAppointment>();
            }

            ServiceResource serviceResource = serviceResources[0];

            Set<String> preferredRegions = new Set<String>();
            if (String.isNotBlank(serviceResource.HOT_PreferredRegions__c)) {
                for (String region : serviceResource.HOT_PreferredRegions__c.split(';')) {
                    preferredRegions.add(region.trim());
                }
            }

            List<ServiceResourceSkill> serviceResourceSkills = [
                SELECT SkillId
                FROM ServiceResourceSkill
                WHERE ServiceResourceId = :serviceResource.Id AND (EffectiveEndDate = NULL OR EffectiveEndDate > TODAY)
            ];

            Set<Id> mySkillIds = new Set<Id>();
            for (ServiceResourceSkill srSkill : serviceResourceSkills) {
                mySkillIds.add(srSkill.SkillId);
            }

            List<HOT_InterestedResource__c> interestedResources = [
                SELECT ServiceAppointment__c
                FROM HOT_InterestedResource__c
                WHERE ServiceResource__c = :serviceResource.Id AND Status__c != NULL
            ];

            Set<Id> interestedServiceAppointmentIds = new Set<Id>();
            for (HOT_InterestedResource__c ir : interestedResources) {
                interestedServiceAppointmentIds.add(ir.ServiceAppointment__c);
            }

            List<ServiceAppointment> serviceAppointments = [
                SELECT
                    Id,
                    Subject,
                    AppointmentNumber,
                    SchedStartTime,
                    SchedEndTime,
                    Status,
                    HOT_DeadlineDate__c,
                    HOT_ServiceTerritoryName__c,
                    WorkType.Id
                FROM ServiceAppointment
                WHERE
                    HOT_IsReleasedToFreelance__c = TRUE
                    AND Status = 'Released to Freelance'
                    AND HOT_DeadlineDate__c >= :DATE.TODAY()
                    AND Id NOT IN :interestedServiceAppointmentIds
                    AND ServiceTerritoryId != NULL
                    AND SchedEndTime > :earliestAppointmentEnd
                    AND SchedStartTime < :latestAppointmentStart
                ORDER BY SchedStartTime ASC
            ];

            List<ServiceAppointment> regionFilteredAppointments = new List<ServiceAppointment>();
            for (ServiceAppointment sa : serviceAppointments) {
                if (
                    preferredRegions.isEmpty() ||
                    String.isBlank(sa.HOT_ServiceTerritoryName__c) ||
                    preferredRegions.contains(sa.HOT_ServiceTerritoryName__c)
                ) {
                    regionFilteredAppointments.add(sa);
                }
            }

            Set<Id> workTypeIds = new Set<Id>();
            for (ServiceAppointment sa : regionFilteredAppointments) {
                if (sa.WorkType != null) {
                    workTypeIds.add(sa.WorkType.Id);
                }
            }

            List<SkillRequirement> neededSkillRequirements = [
                SELECT SkillId, RelatedRecordId
                FROM SkillRequirement
                WHERE RelatedRecordId IN :workTypeIds
            ];

            Map<Id, Set<Id>> workTypeToRequiredSkillIds = new Map<Id, Set<Id>>();
            for (SkillRequirement requirement : neededSkillRequirements) {
                if (!workTypeToRequiredSkillIds.containsKey(requirement.RelatedRecordId)) {
                    workTypeToRequiredSkillIds.put(requirement.RelatedRecordId, new Set<Id>());
                }
                workTypeToRequiredSkillIds.get(requirement.RelatedRecordId).add(requirement.SkillId);
            }

            List<ServiceAppointment> filteredAppointments = new List<ServiceAppointment>();
            for (ServiceAppointment sa : regionFilteredAppointments) {
                Set<Id> requiredSkillIds = workTypeToRequiredSkillIds.get(sa.WorkType.Id);
                Boolean hasAllSkills = true;

                if (requiredSkillIds != null) {
                    for (Id requiredSkillId : requiredSkillIds) {
                        if (!mySkillIds.contains(requiredSkillId)) {
                            hasAllSkills = false;
                            break;
                        }
                    }
                }

                if (hasAllSkills) {
                    filteredAppointments.add(sa);
                }
            }

            return filteredAppointments;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<CalendarEvent> getCalendarEvents(
        Long earliestEventEndTimeInMilliseconds,
        Long latestEventStartInMilliseconds
    ) {
        List<CalendarEvent> events = new List<CalendarEvent>();

        DateTime earliestTime = DateTime.newInstance(earliestEventEndTimeInMilliseconds);
        DateTime latestTime = DateTime.newInstance(latestEventStartInMilliseconds);

        List<ServiceAppointment> openServiceAppointments = getUserOpenServiceAppointments(earliestTime, latestTime);
        List<ServiceAppointment> appointments = getUserServiceAppointments(earliestTime, latestTime);
        List<HOT_WageClaim__c> openWageClaims = getUserOpenWageClaims(earliestTime, latestTime);
        List<HOT_WageClaim__c> newTypeWageClaims = getUserWageClaimsOfNewType(earliestTime, latestTime);
        List<ResourceAbsence> absences = getUserResourceAbsence(earliestTime, latestTime);

        for (ServiceAppointment appointment : openServiceAppointments) {
            CalendarEvent event = new CalendarEvent();
            event.id = appointment.Id;
            event.appointmentNumber = appointment.AppointmentNumber;
            event.type = EventType.OPEN_SERVICE_APPOINTMENT.toString();
            event.startTime = appointment.SchedStartTime;
            event.endTime = appointment.SchedEndTime;
            event.description = appointment.Subject;
            events.add(event);
        }

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

        for (HOT_WageClaim__c claim : newTypeWageClaims) {
            CalendarEvent event = new CalendarEvent();
            event.id = claim.Id;
            event.appointmentNumber = claim.ServiceAppointmentName__c;
            event.type = EventType.WAGE_CLAIM_NEW_TYPE.toString();
            event.startTime = claim.StartTime__c;
            event.endTime = claim.EndTime__c;
            event.description = 'Rett på honorar';
            events.add(event);
        }

        for (ResourceAbsence absence : absences) {
            CalendarEvent event = new CalendarEvent();
            event.id = absence.Id;
            event.type = EventType.RESOURCE_ABSENCE.toString();
            event.appointmentNumber = 'Fravær';
            event.startTime = absence.Start;
            event.endTime = absence.End;
            switch on absence.Type {
                when 'Medical' {
                    event.description = 'Sykdom';
                }
                when 'Vacation' {
                    event.description = 'Ferie';
                }
                when else {
                    event.description = 'Annet';
                }
            }
            events.add(event);
        }

        return events;
    }

    @TestVisible
    private static List<ServiceAppointment> getUserOpenServiceAppointments(
        DateTime earliestAppointmentEnd,
        DateTime latestAppointmentStart
    ) {
        return new OpenServiceAppointmentSelector()
            .getOpenServiceAppointments(earliestAppointmentEnd, latestAppointmentStart);
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
            SELECT Id, StartTime__c, EndTime__c, ServiceAppointmentName__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__r.Id = :resourceId
                AND Status__c = 'Open'
                AND EndTime__c > :earliestWageClaimEnd
                AND StartTime__c < :latestWageClaimStart
        ];
    }

    @TestVisible
    private static List<HOT_WageClaim__c> getUserWageClaimsOfNewType(
        DateTime earliestWageClaimEnd,
        DateTime latestWageClaimStart
    ) {
        Id resourceId = getUserServiceResourceId();
        return [
            SELECT Id, StartTime__c, EndTime__c, ServiceResource__r.Id, Status__c, ServiceAppointmentName__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__r.Id = :resourceId
                AND Type__c = 'Claim on Wage'
                AND EndTime__c > :earliestWageClaimEnd
                AND StartTime__c < :latestWageClaimStart
        ];
    }

    @TestVisible
    private static List<ResourceAbsence> getUserResourceAbsence(
        DateTime earliestAbsenceStart,
        DateTime latestAbsenceStart
    ) {
        Id resourceId = getUserServiceResourceId();
        return [
            SELECT Id, Start, End, Type
            FROM ResourceAbsence
            WHERE ResourceId = :resourceId AND Start < :latestAbsenceStart AND End > :earliestAbsenceStart
        ];
    }

    @TestVisible
    private static Id getUserServiceResourceId() {
        Id currentUserId = UserInfo.getUserId();
        List<ServiceResource> resource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :currentUserId];
        return (resource.isEmpty()) ? null : resource[0].Id;
    }
}
