public without sharing class HOT_InvoiceReminderBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_InvoiceReminderBatch instance = new HOT_InvoiceReminderBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, ServiceAppointment__c, ServiceResource__c FROM HOT_Invoice__c WHERE Status__c = \'Sent In Return\' OR Status__c = \'New\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<HOT_Invoice__c> records) {
        HOT_InvoiceNotification.sendInvoiceNotification(records, 'Reminder');
    }

    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            try {
                System.schedule('HOT_InvoiceReminderBatch_0700', '0 0 7 * * ?', new HOT_InvoiceReminderBatch());
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
