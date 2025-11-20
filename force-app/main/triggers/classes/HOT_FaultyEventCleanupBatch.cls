public without sharing class HOT_FaultyEventCleanupBatch implements Database.Batchable<SObject> {
    private static final Integer DEFAULT_SCOPE_SIZE = 200;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RecordTypeId, Subject, WhatId, Description
            FROM Event
            WHERE RecordType.DeveloperName = 'HOT_Events'
                AND Subject LIKE 'SA-%'
                AND WhatId = NULL
        ]); // Gjenstående filtrering på description håndteres inni HOT_EventHandler.deleteFaultyOutlookSyncEvents.
    }

    public void execute(Database.BatchableContext bc, List<Event> scope) {
        HOT_EventHandler.deleteFaultyOutlookSyncEvents(scope);
    }

    public void finish(Database.BatchableContext bc) {
        // Trenger ingen post processing.
    }

    public static Id run(Integer scopeSize) {
        Integer chunkSize = (scopeSize == null || scopeSize <= 0) ? DEFAULT_SCOPE_SIZE : scopeSize;
        return Database.executeBatch(new HOT_FaultyEventCleanupBatch(), chunkSize);
    }
}
