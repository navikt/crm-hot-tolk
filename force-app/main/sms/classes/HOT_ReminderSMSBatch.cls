public without sharing class HOT_ReminderSMSBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_ReminderSMSBatch instance = new HOT_ReminderSMSBatch();
        database.executebatch(instance);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date dayAfterTomorrow = Date.today().addDays(2);
        String query = 'SELECT ';
        query += 'Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate ';
        query += 'FROM WorkOrder ';
        query += 'WHERE StartDate < :dayAfterTomorrow ';
        query += 'AND StartDate > :Date.today() ';
        query += 'AND Status = \'Dispatched\' ';
        query += 'AND Account.CRM_Person__r.HOT_IsWantSMSReminder__c = TRUE ';
        //query += 'AND Id IN :workOrderIds ';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        HOT_ReminderSMSService.ReminderSMS(records);
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
