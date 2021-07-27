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
        }

        if (serviceAppointmentEvents.size() > 0) {
            setDefaultValuesSA(serviceAppointmentEvents, serviceAppointmentIds);
        }
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<Event> serviceAppointmentEvents = new List<Event>();
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
        }

        if (serviceAppointmentEvents.size() > 0) {
            setDefaultValuesSA(serviceAppointmentEvents, serviceAppointmentIds);
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
}
