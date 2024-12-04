public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT City, Street, Country, PostalCode, Status FROM ServiceAppointment WHERE SchedStartTime > 2021-12-01T00:00:00.000+00:00 AND SchedStartTime < 2024-12-01T00:00:00.000+00:00 AND Status = \'Dispatched\' AND HOT_Processed__c = false AND HOT_IsReleasedToFreelance__c = true'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        for (ServiceAppointment sa : records) {
            sa.Country = sa.Country == null ? 'Norge' : sa.Country;
            sa.City = sa.City == null ? 'N/A' : sa.City;
            sa.Street = sa.Street == null ? 'N/A' : sa.Street;
            sa.PostalCode = sa.PostalCode == null ? 'N/A' : sa.PostalCode;
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
