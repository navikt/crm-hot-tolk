public without sharing class HOT_SMSStatusChangeServiceBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        String query = 'SELECT ';
        query += 'Id, AccountId, HOT_Request__r.OrdererPhone__c, Status, StartDate, EndDate ';
        query += 'FROM WorkOrder ';
        query += 'WHERE HOT_Request__r.OrdererPhone__c != null ';
        query += 'AND EndDate > :now ';
        query += 'AND HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c = TRUE ';
        query += 'AND HOT_SendSMSNotificationOnStatusChanged__c = TRUE ';
        query += 'AND (Status = \'Dispatched\' ';
        query += 'OR Status = \'Cannot Complete \')';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        HOT_ReminderSMSService.sendSMSToOtherOrdererOnStatusUpdate(records);
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = HOT_Utility.getMinutes();
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(
                    new HOT_SMSStatusChangeServiceBatch(),
                    'HOT_SMSStatusChangeServiceBatch',
                    (Integer) minutes,
                    10
                );
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
