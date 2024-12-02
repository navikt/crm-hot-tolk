public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT City, Street, Country, PostalCode, Status FROM ServiceAppointment WHERE CreatedDate = LAST_N_DAYS:90 AND (Status = \'None\' OR Status = \'Scheduled\' OR Status = \'Dispatched\' OR Status = \'Release to Freelance\')'
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
