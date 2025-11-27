public without sharing class HOT_FaultyEventCleanupBatch implements Database.Batchable<SObject>, Schedulable {
    private static final Integer DEFAULT_SCOPE_SIZE = 200;
    private static final String JOB_NAME = 'HOT Faulty Event Cleanup';
    private static final List<Integer> RUN_MINUTES = new List<Integer>{ 0, 15, 30, 45 };

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RecordTypeId, Subject, WhatId, Description
            FROM Event
            WHERE RecordType.DeveloperName = 'HOT_Events'
                AND Subject LIKE 'SA-%'
                AND WhatId = NULL
        ]); // Description-filter håndteres i deleteFaultyOutlookSyncEvents.
    }

    public void execute(Database.BatchableContext bc, List<Event> scope) {
        deleteFaultyOutlookSyncEvents(scope);
    }

    public void finish(Database.BatchableContext bc) {
        // Trenger ingen post processing.
    }

    public void execute(SchedulableContext sc) {
        run(null);
    }

    public static Id run(Integer scopeSize) {
        Integer chunkSize = (scopeSize == null || scopeSize <= 0) ? DEFAULT_SCOPE_SIZE : scopeSize;
        return Database.executeBatch(new HOT_FaultyEventCleanupBatch(), chunkSize);
    }

    public static List<String> scheduleEvery15Minutes() {
        return scheduleEvery15Minutes(null);
    }

    public static List<String> scheduleEvery15Minutes(String jobNamePrefix) {
        List<String> jobIds = new List<String>();
        String baseJobName = String.isNotBlank(jobNamePrefix) ? jobNamePrefix : JOB_NAME;

        for (Integer minute : RUN_MINUTES) {
            String minuteLabel = minute < 10 ? '0' + minute : String.valueOf(minute);
            String cronExpression = '0 ' + minute + ' * * * ?';
            String jobName = baseJobName + ' ' + minuteLabel;
            jobIds.add(System.schedule(jobName, cronExpression, new HOT_FaultyEventCleanupBatch()));
        }

        return jobIds;
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
                        logger.error(
                            'Failed to delete faulty Outlook-synced Event. Reason: ' + err.getMessage(),
                            v,
                            CRM_ApplicationDomain.Domain.HOT
                        );
                    }
                }
            }

            logger.publish();
        }
    }
}
