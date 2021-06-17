public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Id, SchedStartTime, SchedEndTime, HOT_StartHour__c, HOT_EndHour__c FROM ServiceAppointment WHERE SchedStartTime != null AND SchedEndTime != null AND HOT_StartHour__c = null AND HOT_EndHour__c = null'
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
