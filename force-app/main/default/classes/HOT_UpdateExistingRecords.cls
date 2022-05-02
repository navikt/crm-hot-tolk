public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator('SELECT HOT_Interpreters__c FROM WorkOrder WHERE Status != \'Completed\' AND Status != \'Partially Complete\' AND Status != \'Dispatched\' && HOT_Interpreter__c == null');
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        Set<Id> workOrderIds = new Set<Id>();
        for (WorkOrder workOrder : records) {
            workOrderIds.add(workOrder.Id);
        }
        HOT_InterpreterOnWorkOrderService.setInterpreterOnWorkOrder(workOrderIds);
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
