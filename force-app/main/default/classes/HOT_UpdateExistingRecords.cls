public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();

        return Database.getQueryLocator(
            'SELECT Id, AccountId, HOT_Request__c FROM WorkOrder WHERE HOT_Request__c =  \'a147U000000YfhsQAC\''
        );
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        for (WorkOrder wo : records) {
            wo.AccountId = '0012o00002oZOguAAG';
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
