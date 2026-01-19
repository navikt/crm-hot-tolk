public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, HOT_IsImageInterpreter__c, HOT_AutoDispatch__c, Status FROM ServiceAppointment WHERE (HOT_AutoDispatch__c = true AND HOT_IsImageInterpreter__c = true) AND (Status NOT IN ((\'Annul\', \'Completed\', \'Cannot Complete\'))'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {

        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();

        for(ServiceAppointment sa : records) {
            sa.HOT_AutoDispatch__c = false; 
            saToUpdate.add(sa);
        }

        if(!saToUpdate.isEmpty()) {
            update saToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
