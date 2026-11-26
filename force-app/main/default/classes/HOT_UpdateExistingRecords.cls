public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Location, WhatId, Subject FROM Event WHERE RecordType.Name = \'HOT Events\' AND CreatedDate = THIS_WEEK AND WhatId != null AND (NOT Subject LIKE \'SA%\')'
        );
    }

    public void execute(Database.BatchableContext bc, List<Event> records) {
        
        Set<Id> saIds = new Set<Id>();
        for (Event ev : records) {
            saIds.add(ev.WhatId);
        }

        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
            SELECT Id, Address, AppointmentNumber, WorkType.Name, HOT_AddressFormated__c FROM ServiceAppointment WHERE Id IN :saIds
            ]
        );

        if (!serviceAppointments.isEmpty()) {
            for (Event ev : records) {
                ServiceAppointment sa = serviceAppointments.get(ev.WhatId);
                if (sa != null) {
                    ev.Subject = sa.AppointmentNumber +
                ': ' +
                sa.WorkType.Name;
                ev.Location = sa.HOT_AddressFormated__c;
                ev.Description = 'Link til TinD: https://navdialog.lightning.force.com/lightning/r/ServiceAppointment/' +
                sa.Id +
                '/view';
                }
            }
        }

        update records;
    }

    public void finish(Database.BatchableContext bc) {
    }
}
