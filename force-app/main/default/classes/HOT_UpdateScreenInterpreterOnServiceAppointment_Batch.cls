global without sharing class HOT_UpdateScreenInterpreterOnServiceAppointment_Batch implements Database.Batchable<sObject> {
    
    // To run: 
    // HOT_UpdateScreenInterpreterOnServiceAppointment_Batch batchObject = new HOT_UpdateScreenInterpreterOnServiceAppointment_Batch(); 
    // Database.executeBatch(batchObject, 100);

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, HOT_IsScreenInterpreterNew__c FROM ServiceAppointment WHERE HOT_IsScreenInterpreterNew__c = false AND HOT_IsScreenInterpreter__c = true');
    }

    global void execute(Database.BatchableContext bc, List<ServiceAppointment> scope){
        for (ServiceAppointment serviceAppointment : scope) {
			serviceAppointment.HOT_IsScreenInterpreterNew__c = true;
        }
        update scope;
    }

    global void finish(Database.BatchableContext bc){}
}
