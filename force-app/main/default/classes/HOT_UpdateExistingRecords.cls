public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Id, SchedStartTime, SchedEndTime, EarliestStartTime, DueDate, HOT_StartHour__c, HOT_EndHour__c FROM ServiceAppointment WHERE EarliestStartTime != null AND DueDate != null AND HOT_DatesOutOfSync__c = true'
        );
    }
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        records = HOT_ServiceAppointmentHandler.setStartAndEndHour(records);
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
