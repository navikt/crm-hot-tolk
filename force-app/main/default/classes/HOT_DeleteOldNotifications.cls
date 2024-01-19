public without sharing class HOT_DeleteOldNotifications implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_DeleteOldNotifications instance = new HOT_DeleteOldNotifications();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, CreatedDate FROM HOT_Notification__c WHERE CreatedDate != LAST_N_DAYS:31'
        );
    }

    public void execute(Database.BatchableContext bc, List<HOT_Notification__c> records) {
        delete records;
    }
    public void finish(Database.BatchableContext bc) {
    }
}
