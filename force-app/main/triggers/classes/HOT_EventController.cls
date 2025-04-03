public with sharing class HOT_EventController {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }

    public static void resourceServiceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        Set<Id> serviceAppointmentIdsToDeleteEvents = new Set<Id>();
        Set<Id> serviceAppointmentIdsToCreateEvents = new Set<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            //Når ny tolk er tildelt eller om tolk er endret
            if (
                (serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Dispatched') ||
                (serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c &&
                serviceAppointment.Status == 'Dispatched')
            ) {
                serviceAppointmentIdsToDeleteEvents.add(serviceAppointment.Id);
                serviceAppointmentIdsToCreateEvents.add(serviceAppointment.Id);
            }
            //Når tolk tas av
            if (
                ((oldServiceAppointment.Status == 'Completed' ||
                oldServiceAppointment.Status == 'Dispatched' ||
                oldServiceAppointment.Status == 'In Progress') &&
                (serviceAppointment.Status == null ||
                serviceAppointment.Status == 'Scheduled' ||
                serviceAppointment.Status == 'None')) ||
                (oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c == null)
            ) {
                serviceAppointmentIdsToDeleteEvents.add(serviceAppointment.Id);
            }

            if (serviceAppointment.HOT_AssignedResourceId__c != null && serviceAppointment.Status == 'Dispatched') {
                //Når tidspunkt eller adresse endres
                if (
                    ((serviceAppointment.EarliestStartTime != oldServiceAppointment.EarliestStartTime ||
                    serviceAppointment.DueDate != oldServiceAppointment.DueDate) &&
                    serviceAppointment.EarliestStartTime != null &&
                    oldServiceAppointment.DueDate != null) ||
                    (serviceAppointment.HOT_AddressFormated__c != oldServiceAppointment.HOT_AddressFormated__c &&
                    serviceAppointment.SchedStartTime >= Date.today())
                ) {
                    serviceAppointmentIdsToDeleteEvents.add(serviceAppointment.Id);
                    serviceAppointmentIdsToCreateEvents.add(serviceAppointment.Id);
                }
            }
        }
        if (!serviceAppointmentIdsToDeleteEvents.isEmpty()) {
            deleteExistingEvent(serviceAppointmentIdsToDeleteEvents);
        }
        if (!serviceAppointmentIdsToCreateEvents.isEmpty()) {
            createNewEvent(serviceAppointmentIdsToCreateEvents);
        }
    }
    public static void deleteExistingEvent(Set<Id> serviceAppointmentsIds) {
        if (!serviceAppointmentsIds.isEmpty()) {
            List<Event> eventsToDelete = [SELECT Id FROM Event WHERE WhatId IN :serviceAppointmentsIds];
            try {
                delete eventsToDelete;
            } catch (Exception e) {
                handleException(e);
            }
        }
    }
    public static void createNewEvent(Set<Id> serviceAppointmentsIds) {
        String hotEventRecordTypeId = Schema.getGlobalDescribe()
            .get('Event')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('HOT_Events')
            .getRecordTypeId();

        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                AppointmentNumber,
                WorkType.Name,
                HOT_AddressFormated__c,
                EarliestStartTime,
                DueDate,
                HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentsIds
        ];
        List<Event> createdEvents = new List<Event>();
        for (ServiceAppointment sa : serviceAppointments) {
            Event newEvent = new Event();
            newEvent.WhatId = sa.Id;
            newEvent.OwnerId = sa.HOT_AssignedResourceId__c;
            newEvent.RecordTypeId = hotEventRecordTypeId;
            newEvent.Subject = sa.AppointmentNumber + ': ' + sa.WorkType.Name;
            newEvent.Location = sa.HOT_AddressFormated__c;
            newEvent.StartDateTime = sa.EarliestStartTime;
            newEvent.EndDateTime = sa.DueDate;
            newEvent.Description =
                'Link til TinD: https://navdialog.lightning.force.com/lightning/r/ServiceAppointment/' +
                sa.Id +
                '/view';
            newEvent.HOT_IsCreatedFromSA__c = true;
            newEvent.isReminderSet = true;
            newEvent.ReminderDateTime = newEvent.StartDateTime.addHours(-1);
            newEvent.FSL__Event_Type__c = 'Service Appointment';
            createdEvents.add(newEvent);
        }
        if (createdEvents.size() != null) {
            try {
                insert createdEvents;
            } catch (Exception e) {
                handleException(e);
            }
        }
    }
}
