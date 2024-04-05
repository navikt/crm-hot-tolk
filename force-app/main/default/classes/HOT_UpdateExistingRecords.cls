public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, HOT_ParticipantIds__c, HOT_Thread_read_by__c, CRM_Thread_Type__c, CreatedDate FROM Thread__c WHERE (CRM_Thread_Type__c = \'HOT_TOLK-FORMIDLER\' OR CRM_Thread_Type__c = \'HOT_TOLK-TOLK\' OR CRM_Thread_Type__c = \'HOT_BRUKER-TOLK\' OR CRM_Thread_Type__c = \'HOT_TOLK-RESSURSKONTOR\')'
        );
    }

    public void execute(Database.BatchableContext bc, List<Thread__c> records) {
        for (Thread__c thread : records) {
    Set<String> participantIds = new Set<String>();
    Set<String> readByIds = new Set<String>();

    if (String.isNotBlank(thread.HOT_ParticipantIds__c)) {
        if (thread.HOT_ParticipantIds__c.contains(',')) {
            participantIds = new Set<String>(thread.HOT_ParticipantIds__c.split(', '));
        } else {
            participantIds.add(thread.HOT_ParticipantIds__c);
        }
    }
    if (String.isNotBlank(thread.HOT_Thread_read_by__c)) {
        readByIds = new Set<String>(thread.HOT_Thread_read_by__c.split(';'));
    }
    for (String participantId : participantIds) {
        if (!readByIds.contains(participantId)) {
            if (String.isNotBlank(thread.HOT_Thread_read_by__c)) {
                thread.HOT_Thread_read_by__c += ';' + participantId;
            } else {
                thread.HOT_Thread_read_by__c = participantId;
            }
        }
    }
    update records;
}
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
