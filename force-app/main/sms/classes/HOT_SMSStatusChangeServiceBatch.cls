public without sharing class HOT_SMSStatusChangeServiceBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        String query = 'SELECT ';
        query += 'Id, HOT_Request__r.Orderer__c, HOT_Request__r.OrdererPhone__c, HOT_Request__r.Type__c, Status, StartDate, EndDate, HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c, AccountId, Account.CRM_Person__c, Account.CRM_Person__r.INT_KrrMobilePhone__c , HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c ';
        query += 'FROM WorkOrder ';
        query += 'WHERE HOT_SendSMSNotificationOnStatusChanged__c = TRUE ';
        query += 'AND HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c = \'SMS\' ';
        query += 'AND HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c = \'TRUE\'';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        try {
            HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(records);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = HOT_Utility.getMinutesUntilNextSMSBatch();
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
