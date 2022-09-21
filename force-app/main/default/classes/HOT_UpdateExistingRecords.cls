public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, HOT_Request__r.Company__c FROM ServiceAppointment WHERE  HOT_Request__r.Company__c != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        for(ServiceAppointment sa: records){
            if(sa.HOT_Company__c!=null){
                sa.HOT_Company__c = sa.HOT_Request__r.Company__c;
            }
            
        }
        update ServiceAppointments;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
