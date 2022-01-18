public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Subject__c, UserSubject__c,Description__c, UserDescription__c, (SELECT Subject, HOT_UserSubject__c, Description, HOT_UserDescription__c FROM HOT_Request__c.Work_Orders__r WHERE Subject != NULL AND HOT_UserSubject__c = NULL) FROM HOT_Request__c WHERE Subject__c != NULL AND UserSubject__c = NULL'
        );
    }

    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {
        for (HOT_Request__c req : records) {
            req.UserSubject__c = req.Subject__c;
            req.UserDescription__c = req.Description__c;
            for (WorkOrder wo : req.Work_Orders__r) {
                wo.HOT_UserSubject__c = wo.Subject;
                wo.HOT_UserDescription__c = wo.Description;
            }
        }

        try {
            update records;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
