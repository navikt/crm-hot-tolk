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
        Set<Id> toDelete = new Set<Id>();
        Set<Id> toCreate = new Set<Id>();

        Set<Id> saIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            saIds.add(sa.Id);
        }

        //hent eksisterende events først
        Map<Id, Event> existingEvents = new Map<Id, Event>();
        for (Event ev : [
            SELECT Id, WhatId, Location, StartDateTime, EndDateTime, Subject
            FROM Event
            WHERE WhatId IN :saIds
        ]) {
            existingEvents.put(ev.WhatId, ev);
        }

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            Boolean eventExists = existingEvents.containsKey(serviceAppointment.Id);

            //Når ny tolk er tildelt eller om tolk er endret. skal slette og opprette nytt event
            if (
                (serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Dispatched') ||
                (serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c &&
                serviceAppointment.Status == 'Dispatched')
            ) {
                if (eventExists) {
                    toDelete.add(serviceAppointment.Id);
                }
                if (serviceAppointment.HOT_IsEmployedInterpreter__c) {
                    toCreate.add(serviceAppointment.Id);
                }
            }

            //Når tolk tas av. skal slette event
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
                if (eventExists) {
                    toDelete.add(serviceAppointment.Id);
                }
            }

            if (serviceAppointment.HOT_AssignedResourceId__c != null && serviceAppointment.Status == 'Dispatched') {
                //Når tidspunkt eller adresse endres. skal oppdatere event.
                if (
                    ((serviceAppointment.EarliestStartTime != oldServiceAppointment.EarliestStartTime ||
                    serviceAppointment.DueDate != oldServiceAppointment.DueDate) &&
                    serviceAppointment.EarliestStartTime != null &&
                    oldServiceAppointment.DueDate != null) ||
                    (serviceAppointment.HOT_AddressFormated__c != oldServiceAppointment.HOT_AddressFormated__c &&
                    serviceAppointment.SchedStartTime >= Date.today())
                ) {
                    if (serviceAppointment.HOT_IsEmployedInterpreter__c) {
                        if (eventExists) {
                            saToUpdateMap.put(serviceAppointment.Id, serviceAppointment);
                        } else {
                            toCreate.add(serviceAppointment.Id);
                        }
                    }
                }
            }

            //Når oppdraget er ferdig og faktisk start og slutt endres. skal oppdatere event
            if (
                (serviceAppointment.HOT_AssignedResourceId__c == oldServiceAppointment.HOT_AssignedResourceId__c) &&
                (serviceAppointment.ActualStartTime != oldServiceAppointment.ActualStartTime ||
                serviceAppointment.ActualEndTime != oldServiceAppointment.ActualEndTime)
            ) {
                if (serviceAppointment.HOT_IsEmployedInterpreter__c) {
                    if (eventExists) {
                        saToUpdateMap.put(serviceAppointment.Id, serviceAppointment);
                    } else {
                        toCreate.add(serviceAppointment.Id);
                    }
                }
            }
        }
        if (!saToUpdateMap.isEmpty()) {
            updateExistingEvents(existingEvents, saToUpdateMap);
        }

        if (!toDelete.isEmpty()) {
            deleteExistingEvent(existingEvents, toDelete);
        }
        if (!toCreate.isEmpty()) {
            createNewEvent(toCreate);
        }
    }

    public static void deleteExistingEvent(Map<Id, Event> existingEvents, Set<Id> saIdsToDelete) {
        if (!saIdsToDelete.isEmpty()) {
            try {
                List<Event> eventsToDelete = new List<Event>();
                for (Id saId : saIdsToDelete) {
                    Event ev = existingEvents.get(saId);
                    if (ev != null) {
                        eventsToDelete.add(ev);
                    }
                }
                if (!eventsToDelete.isEmpty()) {
                    delete eventsToDelete;
                }
            } catch (Exception e) {
                handleException(e);
            }
        }
    }

    public static void createNewEvent(Set<Id> serviceAppointmentsIds) {
        String hotEventRecordTypeId = Event.sObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('HOT_Events')
            .getRecordTypeId();
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                AppointmentNumber,
                WorkType.Name,
                HOT_WorkTypeName__c,
                HOT_AddressFormated__c,
                EarliestStartTime,
                ActualStartTime,
                ActualEndTime,
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
            newEvent.Subject = sa.AppointmentNumber + ': ' + sa.HOT_WorkTypeName__c;
            newEvent.Location = sa.HOT_AddressFormated__c;
            newEvent.StartDateTime = sa.ActualStartTime != null ? sa.ActualStartTime : sa.EarliestStartTime;
            newEvent.EndDateTime = sa.ActualEndTime != null ? sa.ActualEndTime : sa.DueDate;
            newEvent.Description =
                'Link til TinD: https://navdialog.lightning.force.com/lightning/r/ServiceAppointment/' +
                sa.Id +
                '/view';
            newEvent.HOT_IsCreatedFromSA__c = true;
            newEvent.isReminderSet = true;
            newEvent.ReminderDateTime = newEvent.StartDateTime.addHours(-1);
            createdEvents.add(newEvent);
        }
        if (!createdEvents.isEmpty()) {
            try {
                insert createdEvents;
            } catch (Exception e) {
                handleException(e);
            }
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
            ev.StartDateTime = sa.ActualStartTime != null ? sa.ActualStartTime : sa.EarliestStartTime;
            ev.EndDateTime = sa.ActualEndTime != null ? sa.ActualEndTime : sa.DueDate;

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
