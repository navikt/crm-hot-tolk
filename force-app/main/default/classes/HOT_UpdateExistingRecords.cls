public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator('SELECT HOT_Interpreters__c FROM WorkOrder WHERE Status != \'Completed\' AND Status != \'Partially Complete\' AND Status != \'Dispatched\'');
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        List<WorkOrder> workOrdersWithInterpreterFieldToBeBlank = new List<WorkOrder>();
        for (WorkOrder workOrder : records) {
            workOrder.HOT_Interpreters__c = '';
            workOrdersWithInterpreterFieldToBeBlank.add(workOrder);
        }
        try {
            HOT_DatabaseOperations.updateRecords(workOrdersWithInterpreterFieldToBeBlank);
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
