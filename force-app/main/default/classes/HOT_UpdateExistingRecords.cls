public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator('SELECT Id FROM HOT_Request__c');
    }

    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
