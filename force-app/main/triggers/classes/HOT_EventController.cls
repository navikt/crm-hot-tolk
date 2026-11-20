public without sharing class HOT_EventController {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }

    public static void updateServiceAppointmentEvents(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();

        Set<Id> saIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            saIds.add(sa.Id);
        }

        //hent eksisterende events først
        Map<Id, Event> existingEvents = new Map<Id, Event>();
        for (Event ev : [
            SELECT Id, WhatId, OwnerId, Location, StartDateTime, EndDateTime, Subject
            FROM Event
            WHERE WhatId IN :saIds
        ]) {
            existingEvents.put(ev.WhatId, ev);
        }

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            Boolean eventExists = existingEvents.containsKey(serviceAppointment.Id);
            
            // Når tolk er endret, oppdater eventet 

            Boolean canUpdateEvent =
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.Status == 'Dispatched' &&
                serviceAppointment.HOT_IsEmployedInterpreter__c &&
                eventExists;

            Boolean assignedResourceChanged =
                oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c !=
                    oldServiceAppointment.HOT_AssignedResourceId__c;

            Boolean upcomingAddressChanged =
                serviceAppointment.HOT_AddressFormated__c !=
                    oldServiceAppointment.HOT_AddressFormated__c &&
                serviceAppointment.SchedStartTime >= Date.today();

            if (canUpdateEvent && (assignedResourceChanged || upcomingAddressChanged)) {
                saToUpdateMap.put(serviceAppointment.Id, serviceAppointment);
            } 
        }

        
        if (!saToUpdateMap.isEmpty()) {
            updateExistingEvents(existingEvents, saToUpdateMap);
        }
    }

    public static void updateExistingEvents(Map<Id, Event> existingEvents, Map<Id, ServiceAppointment> updatedSA) {
        List<Event> eventsToUpdate = new List<Event>();

        for (Id saId : updatedSA.keySet()) {
            Event ev = existingEvents.get(saId);
            if (ev == null)
                continue;

            ServiceAppointment sa = updatedSA.get(saId);

            ev.Location = sa.HOT_AddressFormated__c;
            ev.OwnerId = sa.HOT_AssignedResourceId__c;

            eventsToUpdate.add(ev);
        }

        if (!eventsToUpdate.isEmpty()) {
            try {
                update eventsToUpdate;
            } catch (Exception e) {
                handleException(e);
            }
        }
    }
}
