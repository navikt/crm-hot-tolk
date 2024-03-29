public without sharing class HOT_ServiceAppointmentStatusUpdateBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_ServiceAppointmentStatusUpdateBatch instance = new HOT_ServiceAppointmentStatusUpdateBatch();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime today = Datetime.now();
        return Database.getQueryLocator(
            [
                SELECT Id, HOT_Request__c, Status
                FROM ServiceAppointment
                WHERE (Status = 'Released to Freelance' OR Status = 'None') AND SchedEndTime < :today
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
                    new HOT_ServiceAppointmentStatusUpdateBatch(),
                    'HOT_ServiceAppointmentStatusUpdateBatch',
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
