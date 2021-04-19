public without sharing class HOT_EventHandler extends MyTriggers {
    String hotEventRecordTypeId = Schema.getGlobalDescribe()
        .get('Event')
        .getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('HOT_Events')
        .getRecordTypeId();

    public override void onBeforeInsert() {
        List<Event> serviceAppointmentEvents = new List<Event>();
        List<Event> resourceAbsenceEvents = new List<Event>();
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (Event event : (List<Event>) records) {
            // Filtrer ut de som er koblet til ett oppdrag og er av type HOT Event
            if (
                event.RecordTypeId == hotEventRecordTypeId &&
                event.WhatId?.getSobjectType() == Schema.ServiceAppointment.SObjectType
            ) {
                serviceAppointmentEvents.add(event);
                serviceAppointmentIds.add(event.WhatId);
            }

            // Filtrer ut de som blir synket fra Outlook (eller opprettes manuelt) og er av type HOT Event
            if (event.RecordTypeId == hotEventRecordTypeId && event.WhatId == null) {
                resourceAbsenceEvents.add(event);
            }
        }

        if (serviceAppointmentEvents.size() > 0) {
            setDefaultValuesSA(serviceAppointmentEvents, serviceAppointmentIds);
        }
        if (resourceAbsenceEvents.size() > 0) {
            setDefaultValuesRA(resourceAbsenceEvents);
        }
    }

    public override void onAfterInsert() {
        List<Event> resourceAbsenceEvents = new List<Event>();

        for (Event event : (List<Event>) records) {
            // Filtrer ut de som blir synket fra Outlook (eller opprettes manuelt) og er av type HOT Event
            // For å komme "riktig" i forhold til FSL-triggerne måtte denne legges til After Insert
            if (event.RecordTypeId == hotEventRecordTypeId && event.WhatId == null && event.IsRecurrence2 == false) {
                resourceAbsenceEvents.add(event);
            }
        }

        if (resourceAbsenceEvents.size() > 0) {
            updateRAEvents(resourceAbsenceEvents);
        }
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<Event> serviceAppointmentEvents = new List<Event>();
        List<Event> resourceAbsenceEvents = new List<Event>();
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (Event event : (List<Event>) records) {
            // Filtrer ut de som er koblet til ett oppdrag og er av type HOT Event
            if (
                event.RecordTypeId == hotEventRecordTypeId &&
                event.WhatId?.getSobjectType() == Schema.ServiceAppointment.SObjectType
            ) {
                serviceAppointmentEvents.add(event);
                serviceAppointmentIds.add(event.WhatId);
            }

            // Filtrer ut de som er koblet til ett ressursfravær og er av type HOT Event
            if (
                event.RecordTypeId == hotEventRecordTypeId &&
                event.WhatId?.getSobjectType() == Schema.ResourceAbsence.SObjectType
            ) {
                resourceAbsenceEvents.add(event);
            }
        }

        if (serviceAppointmentEvents.size() > 0) {
            setDefaultValuesSA(serviceAppointmentEvents, serviceAppointmentIds);
        }
        if (resourceAbsenceEvents.size() > 0) {
            setDefaultValuesRA(resourceAbsenceEvents);
        }
    }

    private static void setDefaultValuesSA(List<Event> events, Set<Id> serviceAppointmentIds) {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, AppointmentNumber, WorkType.Name, HOT_AddressFormated__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ];
        Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>(serviceAppointments);

        for (Event event : events) {
            event.Subject =
                serviceAppointmentMap.get(event.WhatId)?.AppointmentNumber +
                ': ' +
                serviceAppointmentMap.get(event.WhatId)?.WorkType.Name;
            event.Location = serviceAppointmentMap.get(event.WhatId)?.HOT_AddressFormated__c;
            event.Description =
                'Link til TinD: https://navdialog.lightning.force.com/lightning/r/ServiceAppointment/' +
                serviceAppointmentMap.get(event.WhatId)?.Id +
                '/view';
        }
    }

    private static void setDefaultValuesRA(List<Event> events) {
        Set<String> eventFields = Schema.SObjectType.Event.fields.getMap().keySet();

        for (Event event : events) {
            if (eventFields.contains('fsl__event_type__c') && event.get('FSL__Event_Type__c') == null) {
                event.Description = null;
            } else if (
                eventFields.contains('fsl__event_type__c') && event.get('FSL__Event_Type__c') == 'Resource Absence'
            ) {
                event.Description = null;
            }
        }
    }

    private static void updateRAEvents(List<Event> events) {
        Set<String> eventFields = Schema.SObjectType.Event.fields.getMap().keySet();
        List<Event> eventsToUpdate = new List<Event>();

        for (Event event : events) {
            if (eventFields.contains('fsl__event_type__c') && event.get('FSL__Event_Type__c') == null) {
                Event eventClone = new Event(Id = event.Id);
                eventClone.put('FSL__Event_Type__c', 'Resource Absence');
                eventsToUpdate.add(eventClone);
            }
        }
        update eventsToUpdate;
    }
}
