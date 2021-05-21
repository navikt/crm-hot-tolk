public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Id IsReminderSMS__c, Account__r.CRM_Person__c FROM HOT_Request__c WHERE IsReminderSMS__c = FALSE AND StartTime__c > :now'
        );
    }
    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {
        List<Id> personIds = new List<Id>();
        for (HOT_Request__c request : records) {
            request.IsReminderSMS__c = true;
            personIds.add(request.Account__r.CRM_Person__c);
        }

        try {
            update records;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
