public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, HOT_Request__r.Company__c, HOT_Company__c FROM ServiceAppointment WHERE HOT_Request__r.Company__c != null AND HOT_Company__c = null'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> ServiceAppointments) {
        for (ServiceAppointment sa : ServiceAppointments) {
            if (sa.HOT_Company__c == null) {
                sa.HOT_Company__c = sa.HOT_Request__r.Company__c;
            }
        }
        update ServiceAppointments;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
