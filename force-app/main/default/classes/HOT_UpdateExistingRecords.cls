public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT HOT_Dispatcher__c, HOT_DispatcherNew__c, HOT_Request__r.Dispatcher__c FROM ServiceAppointment WHERE HOT_DispatcherNew__c = NULL AND HOT_Dispatcher__c != NULL'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        for (ServiceAppointment sa : records) {
            sa.HOT_DispatcherNew__c = sa.HOT_Request__r.Dispatcher__c;
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
