public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE (Status = \'Completed\' OR Status = \'Partially Complete\' OR Status = \'Dispatched\') AND HOT_Interpreters__c = null'
        );
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(records);
        HOT_InterpreterOnWorkOrderService.setInterpreterOnWorkOrder(workOrderMap.keySet());

        List<ServiceAppointment> ServiceAppointments = [SELECT Id, HOT_Request__r.Company__c FROM ServiceAppointment WHERE  HOT_Request__r.Company__c != null];
        for(ServiceAppointment sa: ServiceAppointments){
            if(sa.HOT_Company__c!=null){
                sa.HOT_Company__c = sa.HOT_Request__r.Company__c;
            }
            
        }
        update ServiceAppointments;

    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
