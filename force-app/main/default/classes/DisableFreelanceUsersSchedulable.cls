public with sharing class DisableFreelanceUsersSchedulable implements Database.Batchable<sObject>, Schedulable{
      public void execute(SchedulableContext sc) {
        DisableFreelanceUsersSchedulable instance = new DisableFreelanceUsersSchedulable();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime oneYearAgo = Datetime.now().addDays(-365);

         return Database.getQueryLocator(
            [
                SELECT Id, LastLoginDate, ProfileId FROM User WHERE Profile.Name='NAV Samhandler' AND LastLoginDate <= :oneYearAgo
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

                for (ServiceResource sr : serviceResource) {
                    sr.IsActive = false;
                    relatedRecordIds.add(sr.RelatedRecordId);
                }
                
                List<PermissionSetAssignment> permissionSetAssignmentsToBeDeleted=[SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN: relatedRecordIds AND PermissionSetId=:permissionsetFreelance.Id];
                
                for(User user : records){
                    user.ProfileId=profile.Id;
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
                    update serviceResource;
                    delete permissionSetAssignmentsToBeDeleted;
                    insert newPermissionSetAssignments;
                    update records;
                } catch (Exception e) {
                    LoggerUtility logger = new LoggerUtility();
                    logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                    logger.publish();
                }
            }
            
        }
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}