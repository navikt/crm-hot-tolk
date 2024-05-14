public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select Id, CreatedDate, CRM_Related_Object__c, CRM_Account__c, HOT_ServiceAppointment__c, HOT_InterestedResource__c FROM Thread__c WHERE HOT_IsDone__c =false AND CRM_Thread_Type__c =\'HOT_TOLK-FORMIDLER\' AND HOT_ServiceAppointment__c != null AND CRM_Account__c !=null'
        );
    }

    public void execute(Database.BatchableContext bc, List<Thread__c> records) {
        System.debug('fant ' + records.size());
        Set<String> serviceAppointmentIds = new Set<String>();
        for (Thread__c thread : records) {
            if(thread.CRM_Related_Object__c != null){
                Id relatedobject = thread.CRM_Related_Object__c;
                String objectType = String.valueOf(relatedobject.getsobjecttype());
                if (objectType == 'ServiceAppointment') {
                    serviceAppointmentIds.add(thread.CRM_Related_Object__c);
                }
            }
        }
        Map<Id, List<HOT_InterestedResource__c>> irMap = new Map<Id, List<HOT_InterestedResource__c>>();
        if (!serviceAppointmentIds.isEmpty()) {
            List<HOT_InterestedResource__c> irList = [
                SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__r.AccountId 
                FROM HOT_InterestedResource__c 
                WHERE ServiceAppointment__c IN :serviceAppointmentIds 
                AND Status__c != 'Assigned'
            ];
            for (HOT_InterestedResource__c ir : irList) {
                if (!irMap.containsKey(ir.ServiceAppointment__c)) {
                    irMap.put(ir.ServiceAppointment__c, new List<HOT_InterestedResource__c>());
                }
                irMap.get(ir.ServiceAppointment__c).add(ir);
            }
        }
         // Update the Thread__c records
        List<Thread__c> threadsToUpdate = new List<Thread__c>();
        for (Thread__c thread : records) {
            if (irMap.containsKey(thread.CRM_Related_Object__c)) {
                for (HOT_InterestedResource__c ir : irMap.get(thread.CRM_Related_Object__c)) {
                    if (ir.ServiceResource__r.AccountId == thread.CRM_Account__c) {
                        thread.CRM_Related_Object__c = ir.Id;
                        thread.HOT_ServiceAppointment__c=null;
                        thread.HOT_InterestedResource__c=ir.Id;
                        threadsToUpdate.add(thread);
                    }
                }
            }
        }

        if (!threadsToUpdate.isEmpty()) {
            update threadsToUpdate;
        }       
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
