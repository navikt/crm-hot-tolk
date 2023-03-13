public with sharing class HOT_DisableFreelanceSchedulable implements Database.Batchable<sObject>, Schedulable{
      public void execute(SchedulableContext sc) {
        HOT_DisableFreelanceSchedulable instance = new HOT_DisableFreelanceSchedulable();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime oneYearAgo = Datetime.now().addDays(-365);

        List<AssignedResource> assignedResources = [SELECT ServiceResource.AccountId, ServiceAppointment.SchedEndTime FROM AssignedResource WHERE ServiceAppointment.SchedEndTime <= :oneYearAgo];

        Map<Id, Datetime> serviceResourceIdsToSchedEndTime = new Map<Id, Datetime>();

        for (AssignedResource ar : assignedResources) {
            if (!serviceResourceIdsToSchedEndTime.containsKey(ar.ServiceResource.AccountId)
                    || ar.ServiceAppointment.SchedEndTime > serviceResourceIdsToSchedEndTime.get(ar.ServiceResource.AccountId)) {
                serviceResourceIdsToSchedEndTime.put(ar.ServiceResource.AccountId, ar.ServiceAppointment.SchedEndTime);
            }
        }

        Set<Id> serviceResourceIds = new Set<Id>();
        for (Id serviceResourceId : serviceResourceIdsToSchedEndTime.keySet()) {
            if (serviceResourceIdsToSchedEndTime.get(serviceResourceId) <= oneYearAgo) {
                serviceResourceIds.add(serviceResourceId);
            }
        }
         return Database.getQueryLocator(
            [
                SELECT Id, LastLoginDate, ProfileId 
FROM User 
WHERE Profile.Name='NAV Samhandler' 
AND AccountId IN :serviceResourceIds 
            ]
        );
    }
public void execute(Database.BatchableContext bc, List<User> records) {
    
    if (records.size() > 0) {
        List<ServiceResource> serviceResource=[SELECT Id,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN: records AND HOT_IsFreelanceInterpreter__c=true];
        if(serviceResource.size()>0){
           

            for (ServiceResource sr : serviceResource) {
                sr.IsActive = false;
               
            }
            try{
                update serviceResource;
            }
            catch (Exception e) {
            }
 
    }

}
}

    public void finish(Database.BatchableContext bc) {
        HOT_DisableFreelancePart2Schedulable instance = new HOT_DisableFreelancePart2Schedulable();
        database.executebatch(instance, 10);
    }
}