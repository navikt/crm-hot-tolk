public without sharing class HOT_ServiceAppointmentImageStatus implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_ServiceAppointmentImageStatus instance = new HOT_ServiceAppointmentImageStatus();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime today = Datetime.now();

        return Database.getQueryLocator(
            [
                SELECT Id, HOT_Request__c
                FROM ServiceAppointment
                WHERE Status = 'Dispatched' AND HOT_IsImageInterpreter__c = TRUE AND SchedEndTime < :today
            ]
        );
    }
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        if (records.size() > 0) {
            for (ServiceAppointment sa : records) {
                sa.Status = 'Completed';
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
    }
}
