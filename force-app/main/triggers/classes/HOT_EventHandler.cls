public without sharing class HOT_EventHandler extends MyTriggers {
    public override void onAfterInsert() {
        deleteFaultyOutlookSyncEvents(records);
    }

    public static void deleteFaultyOutlookSyncEvents(List<Event> records) {
        if (records == null || records.isEmpty())
            return;

        Map<Id, Schema.RecordTypeInfo> rtById = Event.SObjectType.getDescribe().getRecordTypeInfosById();

        List<Event> toDelete = new List<Event>();
        List<Event> victims = new List<Event>();

        for (Event e : records) {
            if (e == null || e.Id == null)
                continue;

            if (e.RecordTypeId == null)
                continue;
            Schema.RecordTypeInfo rti = rtById.get(e.RecordTypeId);
            if (rti == null || rti.getDeveloperName() != 'HOT_Events')
                continue;

            if (String.isBlank(e.Subject) || !e.Subject.startsWith('SA-'))
                continue;

            if (e.WhatId != null)
                continue;

            if (String.isBlank(e.Description) || !e.Description.contains('Link til TinD: https://navdialog'))
                continue;

            toDelete.add(new Event(Id = e.Id));
            victims.add(e);
        }

        if (!toDelete.isEmpty()) {
            Database.DeleteResult[] results = Database.delete(toDelete, false);
            LoggerUtility logger = new LoggerUtility('HOT_Events Cleanup');

            for (Integer i = 0; i < results.size(); i++) {
                Database.DeleteResult dr = results[i];
                Event v = victims[i];

                if (dr.isSuccess()) {
                    logger.info('Deleted faulty Outlook-synced Event per HOT_Events criteria.', v, CRM_ApplicationDomain.Domain.HOT);
                } else {
                    for (Database.Error err : dr.getErrors()) {
                        logger.error('Failed to delete faulty Outlook-synced Event. Reason: ' + err.getMessage(), v, CRM_ApplicationDomain.Domain.HOT);
                    }
                }
            }

            logger.publish();
        }
    }
}
