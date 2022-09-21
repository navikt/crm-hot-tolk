public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();

        return Database.getQueryLocator(
            'SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE Status = \'Completed\' AND (ActualStartTime = null OR ActualEndTime = null)'
        );
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(records);
        HOT_InterpreterOnWorkOrderService.setInterpreterOnWorkOrder(workOrderMap.keySet());
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}