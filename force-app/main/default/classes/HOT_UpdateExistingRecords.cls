public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, AccountId, HOT_Account__c FROM ServiceAppointment WHERE HOT_Account__c = null AND AccountId != null'
        );
    }
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        for (ServiceAppointment serviceAppointment : records) {
            serviceAppointment.HOT_Account__c = serviceAppointment.AccountId;
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
