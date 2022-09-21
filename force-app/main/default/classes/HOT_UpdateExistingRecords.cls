public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();

        return Database.getQueryLocator(
            'SELECT Id, Status, ActualStartTime, ActualEndTime, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Status = \'Completed\' AND ActualStartTime = null AND ActualEndTime = null AND SchedStartTime != null AND SchedEndTime != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for (ServiceAppointment sa : records) {
            sa.ActualStartTime = sa.SchedStartTime;
            sa.ActualEndTime = sa.SchedEndTime;
            saList.add(sa);
        }
        update saList;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
