public class HOT_SendReminderSMSBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SendReminderSMSBatch instance = new HOT_SendReminderSMSBatch();
        database.executebatch(instance);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date dayAfterTomorrow = Date.today().addDays(2);
        return Database.getQueryLocator(
            'SELECT Id FROM WorkOrder WHERE StartDate < :dayAfterTomorrow AND StartDate > :Date.today() AND Status = +\'Dispatched\''
        );
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        List<Id> workOrderIds = new List<Id>();
        for (WorkOrder workOrder : records) {
            workOrderIds.add(workOrder.Id);
        }
        HOT_ReminderSMSService.sendReminderSMS(workOrderIds);
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
