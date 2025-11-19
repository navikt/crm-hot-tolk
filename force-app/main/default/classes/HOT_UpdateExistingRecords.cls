public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, InterpretationMethod__c, InterpretationMethodName__c, InterpretationMethodType__c, InterpretationMethodSecondary__c FROM HOT_Request__c WHERE InterpretationMethod__c != null OR InterpretationMethodSecondary__c != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {

        for(HOT_Request__c req : records) {
            if(req.InterpretationMethodType__c == null) {
                req.InterpretationMethodName__c = req.InterpretationMethodType__c;
            }
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
