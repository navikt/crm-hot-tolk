public without sharing class HOT_DisableFreelancePart2Schedulable implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, AccountId
                FROM ServiceResource
                WHERE IsActive = FALSE AND CRM_Domain__c = 'HOT' AND HOT_IsFreelanceInterpreter__c = TRUE
            ]
        );
    }
    public void execute(Database.BatchableContext bc, List<ServiceResource> records) {
        if (records.size() > 0) {
            Set<Id> srAccointIdsToDelete = new Set<Id>();
            for (ServiceResource sr : records) {
                srAccointIdsToDelete.add(sr.AccountId);
            }

            List<User> users = [
                SELECT Id, ProfileId
                FROM User
                WHERE Profile.Name = 'NAV Samhandler' AND AccountId IN :srAccointIdsToDelete
            ];

            PermissionSet permissionsetBrukerPlus = [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name = 'HOT_Tolk_Bruker_Plus'
                LIMIT 1
            ];
            PermissionSetGroup permissionsetFreelance = [
                SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName ='HOT_Tolk_Frilans_Gruppe' LIMIT 1
            ];
            Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'NAV Bruker Plus' LIMIT 1];

            Set<Id> relatedRecordIds = new Set<Id>();


            for (User user : users) {
                user.ProfileId = profile.Id;
                relatedRecordIds.add(user.Id);
            }
            update users;

            PermissionSetLicenseAssign pmSetLicenseList=[SELECT Id,PermissionSetLicense.DeveloperName, AssigneeId FROM PermissionSetLicenseAssign WHERE AssigneeId IN: relatedRecordIds AND (PermissionSetLicense.DeveloperName='FieldServiceSchedulingPsl' OR PermissionSetLicense.DeveloperName='FieldServiceMobilePsl')];
            delete pmSetLicenseList;

            List<PermissionSetAssignment> permissionSetAssignmentsToBeDeleted = [
                 SELECT Id, AssigneeId, PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :relatedRecordIds AND PermissionSetGroup.Id = :permissionsetFreelance.Id
            ];

            List<PermissionSetAssignment> permissionSetAssignments = [
                SELECT Id, AssigneeId, PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :relatedRecordIds
            ];
            Map<Id, Id> assigneeToPermissionSetMap = new Map<Id, Id>();
            for (PermissionSetAssignment psa : permissionSetAssignments) {
                if (psa.PermissionSetId != permissionsetBrukerPlus.Id) {
                        assigneeToPermissionSetMap.put(psa.AssigneeId, permissionsetBrukerPlus.Id);
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
                insert newPermissionSetAssignments;
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
    }
}
