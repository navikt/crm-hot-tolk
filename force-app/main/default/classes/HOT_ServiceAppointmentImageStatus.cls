public without sharing class HOT_ServiceAppointmentImageStatus implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_ServiceAppointmentImageStatus instance = new HOT_ServiceAppointmentImageStatus();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime today = Datetime.now();
        String query='SELECT Id, HOT_Request__c FROM ServiceAppointment WHERE (Status=\'Dispatched\' AND HOT_IsImageInterpreter__c=true) AND SchedEndTime<:today';
       return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
            try {
                for (ServiceAppointment sa : records) {
                    sa.Status = 'Completed';
                }
                update records;
            
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        
    }
    public void finish(Database.BatchableContext bc) {
    }
}
