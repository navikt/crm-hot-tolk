public without sharing class HOT_RemoveAccessForHiddenSABatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_RemoveAccessForHiddenSABatch instance = new HOT_RemoveAccessForHiddenSABatch();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime today = Datetime.now();
        return Database.getQueryLocator(
            [
                SELECT Id, HOT_Request__c, Status
                FROM ServiceAppointment
                WHERE HOT_DelPol_IsHideRecord__c = TRUE AND HOT_DelPol_ToHideRecord__c = TRUE
            ]
        );
    }
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        if (records.size() > 0) {
            for (ServiceAppointment sa : records) {
                sa.Status = 'Cannot Complete';
            }

            try {
                update records;
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(
                    new HOT_RemoveAccessForHiddenSABatch(),
                    'HOT_RemoveAccessForHiddenSABatch',
                    60,
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
