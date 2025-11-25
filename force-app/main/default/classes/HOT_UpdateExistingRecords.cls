public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, InterpretationMethod__c, InterpretationMethod__r.Name, InterpretationMethodType__c, InterpretationMethodSecondary__c, InterpretationMethodSecondary__r.Name, InterpretationMethodSecondaryType__c FROM HOT_Request__c WHERE (InterpretationMethodType__c = null AND (InterpretationMethod__c != null AND InterpretationMethod__r.Name != null)) OR (InterpretationMethodSecondaryType__c = null AND (InterpretationMethodSecondary__c != null AND InterpretationMethodSecondary__r.Name != null))'
        );
    }

    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {

        Map<Id, HOT_Request__c> requestsToUpdateMap = new Map<Id, HOT_Request__c>();

        for(HOT_Request__c req : records) {

            if(req.interpretationMethod__c != null && req.InterpretationMethodType__c != req.InterpretationMethod__r.Name) {

                req.InterpretationMethodType__c = req.InterpretationMethod__r.Name; 
                requestsToUpdateMap.put(req.Id, req);
            }

            if(req.InterpretationMethodSecondary__c != null && req.InterpretationMethodSecondaryType__c != req.InterpretationMethodSecondary__r.Name) {

                req.InterpretationMethodSecondaryType__c = req.InterpretationMethodSecondary__r.Name;
                requestsToUpdateMap.put(req.Id, req);
            }

        }

        if(!requestsToUpdateMap.isEmpty()){
            update requestsToUpdateMap.values();
        }
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
