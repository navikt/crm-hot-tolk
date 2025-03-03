public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Subject,  Street, City, PostalCode FROM ServiceAppointment WHERE HOT_AssignmentType__c = \'Bildetolkvakt\' AND (Street = \'\' OR City = \'\' OR PostalCode = \'\') AND CreatedDate >= LAST_N_DAYS:365'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        for (ServiceAppointment sa : records) {
            sa.Country = 'Norge';
            sa.City = 'N/A';
            sa.Street = 'N/A';
            sa.PostalCode = 'N/A';
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
