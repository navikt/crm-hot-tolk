public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();

        return Database.getQueryLocator(
            'SELECT Id, HOT_NotificationChannel__c FROM Person__c WHERE HOT_HasEntitlement__c =true'
        );
    }

    public void execute(Database.BatchableContext bc, List<Person__c> records) {
        for (Person__c person : records) {
            person.HOT_NotificationChannel__c='SMS';
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
