public with sharing class HOT_DisableFreelancePart2Schedulable implements Database.Batchable<sObject>, Schedulable{
      public void execute(SchedulableContext sc) {
        HOT_DisableFreelancePart2Schedulable instance = new HOT_DisableFreelancePart2Schedulable();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime oneYearAgo = Datetime.now().addDays(-365);
        List<AssignedResource> assignedresource=[SELECT ServiceResource.AccountId FROM AssignedResource WHERE ServiceAppointment.SchedEndTime <= :oneYearAgo];
        Set<Id> serviceResourceIds = new Set<Id>();
        for (AssignedResource ar : assignedResource) {
            serviceResourceIds.add(ar.ServiceResource.AccountId);
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
            PermissionSet permissionset=[SELECT Id, Name FROM PermissionSet WHERE Name='HOT_Tolk_Bruker_Plus' LIMIT 1];
            PermissionSet permissionsetFreelance=[SELECT Id, Name FROM PermissionSet WHERE Name='HOT_Tolk_Frilans' LIMIT 1];
            Profile profile=[SELECT Id, Name FROM Profile WHERE Name='NAV Bruker Plus' LIMIT 1];

            Set<Id> relatedRecordIds = new Set<Id>();

            List<PermissionSetAssignment> permissionSetAssignmentsToBeDeleted=[SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN: relatedRecordIds AND PermissionSetId=:permissionsetFreelance.Id];
            
            for(User user : records){
                user.ProfileId=profile.Id;
                relatedRecordIds.add(user.Id);
            }
            List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :relatedRecordIds];
            Map<Id, Id> assigneeToPermissionSetMap = new Map<Id, Id>();
            for (PermissionSetAssignment psa : permissionSetAssignments) {
                if (psa.PermissionSetId != permissionset.Id) {
                    assigneeToPermissionSetMap.put(psa.AssigneeId, permissionset.Id);
                }
            }
            List<PermissionSetAssignment> newPermissionSetAssignments = new List<PermissionSetAssignment>();
            for (Id assigneeId : assigneeToPermissionSetMap.keySet()) {
                PermissionSetAssignment newPSA = new PermissionSetAssignment();
                newPSA.AssigneeId = assigneeId;
                newPSA.PermissionSetId = assigneeToPermissionSetMap.get(assigneeId);
                newPermissionSetAssignments.add(newPSA);
            }
            try {
                delete permissionSetAssignmentsToBeDeleted;
                update records;
                insert newPermissionSetAssignments;
            } catch (Exception e) {
            }
            
        }
    }
}

    public void finish(Database.BatchableContext bc) {
        
    }
}