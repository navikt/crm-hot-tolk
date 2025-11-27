public without sharing class HOT_ServiceAppointmentsSharingService {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    public static void grantAccess(Map<Id, Id> apppointmentIdByAssignment, Map<Id, Id> resourceByAssignment) {
        Map<Id, Id> userIdyResourceId = getUserIdyResourceId(resourceByAssignment.values());
        Map<Id, Id> woBySa = getWorkOrderIds(apppointmentIdByAssignment.values());
        Map<Id, User> userByUserId = getUserById(userIdyResourceId.values());
        Map<Id, Id> threadBySaId = getThreadBySAId(apppointmentIdByAssignment.values());
        Map<Id, Id> accountIdByServiceAppointmentId = getAccountIdByServiceAppointmentId(
            apppointmentIdByAssignment.values()
        );
        List<ServiceAppointmentShare> serviceAppointmentShares = new List<ServiceAppointmentShare>();
        List<WorkOrderShare> workOrderShares = new List<WorkOrderShare>();
        List<AccountShare> accountShares = new List<AccountShare>();
        List<Thread__Share> threadShares = new List<Thread__Share>();
        for (Id assignmentId : apppointmentIdByAssignment.keySet()) {
            Id resourceId = resourceByAssignment.get(assignmentId);
            Id userId = userIdyResourceId.get(resourceId);
            Id serviceAppointmentId = apppointmentIdByAssignment.get(assignmentId);
            String workOrderAccessLevel = 'Edit';
            if (userByUserId.get(userId).IsPortalEnabled == true) {
                workOrderAccessLevel = 'Read';
            }
            serviceAppointmentShares.add(
                new ServiceAppointmentShare(
                    ParentId = serviceAppointmentId,
                    AccessLevel = 'Edit',
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
            workOrderShares.add(
                new WorkOrderShare(
                    ParentId = woBySa.get(serviceAppointmentId),
                    AccessLevel = workOrderAccessLevel,
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
            accountShares.add(
                new AccountShare(
                    AccountId = accountIdByServiceAppointmentId.get(serviceAppointmentId),
                    AccountAccessLevel = 'Read',
                    CaseAccessLevel = 'None',
                    OpportunityAccessLevel = 'None',
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
            threadShares.add(
                new Thread__Share(
                    ParentId = threadBySaId.get(serviceAppointmentId),
                    AccessLevel = 'Edit',
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
        }
        Database.insert(serviceAppointmentShares, false);
        Database.insert(workOrderShares, false);
        Database.insert(accountShares, false);
        Database.insert(threadShares, false);
    }

    @future
    public static void removeAccessForSpecificUsers(
        Map<Id, Id> apppointmentByAssignment,
        Map<Id, Id> resourceByAssignment
    ) {
        Map<Id, Id> userIdyResourceId = getUserIdyResourceId(resourceByAssignment.values());
        String soqlQuery = 'SELECT Id FROM ServiceAppointmentShare WHERE RowCause =\'Manual\' AND (';
        for (Id assignmentId : apppointmentByAssignment.keySet()) {
            Id resourceId = resourceByAssignment.get(assignmentId);
            Id userId = userIdyResourceId.get(resourceId);
            Id serviceAppointmentId = apppointmentByAssignment.get(assignmentId);
            soqlQuery += ' (UserOrGroupId=\'' + userId + '\' AND ParentId=\'' + serviceAppointmentId + '\') OR';
        }
        soqlQuery = soqlQuery.removeEnd('OR');
        soqlQuery += ')';
        List<ServiceAppointmentShare> serviceAppointmentShares = Database.query((soqlQuery));
        try {
            delete serviceAppointmentShares;
        } catch (Exception e) {
            handleException(e);
        }
    }

    public static void removeManualAccess(Set<Id> serviceAppointIds) {
        List<ServiceAppointmentShare> serviceAppointmentShares = [
            SELECT Id
            FROM ServiceAppointmentShare
            WHERE RowCause = 'Manual' AND ParentId IN :serviceAppointIds
        ];
        try {
            delete serviceAppointmentShares;
        } catch (Exception e) {
            handleException(e);
        }
    }

    private static Map<Id, Id> getUserIdyResourceId(List<Id> resourceIds) {
        Map<Id, Id> userIdyResourceId = new Map<Id, Id>();
        for (ServiceResource sr : [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN :resourceIds]) {
            userIdyResourceId.put(sr.Id, sr.RelatedRecordId);
        }

        return userIdyResourceId;
    }

    private static Map<Id, Id> getThreadBySAId(List<Id> saIds) {
        Map<Id, Id> threadBySAId = new Map<Id, Id>();
        List<Thread__c> threadList = [
            SELECT Id, CRM_Related_Object__c
            FROM Thread__c
            WHERE
                CRM_Related_Object__c IN :saIds
                AND (CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
                OR CRM_Thread_Type__c = 'HOT_TOLK-TOLK'
                OR CRM_Thread_Type__c = 'HOT_BRUKER-TOLK'
                OR CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR')
        ];

        for (Thread__c thread : threadList) {
            threadBySAId.put(thread.CRM_Related_Object__c, thread.Id);
        }

        return threadBySAId;
    }

    private static Map<Id, User> getUserById(List<Id> userIds) {
        return new Map<Id, User>([SELECT Id, IsPortalEnabled FROM User WHERE Id IN :userIds]);
    }

    public static Map<Id, Id> getWorkOrderIds(List<Id> serviceApponntmentIds) {
        Map<Id, Id> workOrderLineByServiceAppointment = new Map<Id, Id>();
        for (ServiceAppointment sa : [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE Id IN :serviceApponntmentIds
        ]) {
            workOrderLineByServiceAppointment.put(sa.Id, sa.ParentRecordId);
        }
        Map<Id, Id> workOrderByLine = new Map<Id, Id>();
        for (WorkOrderLineItem woli : [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id IN :workOrderLineByServiceAppointment.values()
        ]) {
            workOrderByLine.put(woli.Id, woli.WorkOrderId);
        }
        Map<Id, Id> workOrderByServiceAppointment = new Map<Id, Id>();
        for (Id saId : serviceApponntmentIds) {
            Id woliId = workOrderLineByServiceAppointment.get(saId);
            workOrderByServiceAppointment.put(saId, workOrderByLine.get(woliId));
        }

        return workOrderByServiceAppointment;
    }

    public static Map<Id, Id> getAccountIdByServiceAppointmentId(List<Id> serviceApponntmentIds) {
        Map<Id, Id> accountIdByServiceAppointmentId = new Map<Id, Id>();
        for (ServiceAppointment sa : [
            SELECT Id, AccountId
            FROM ServiceAppointment
            WHERE Id IN :serviceApponntmentIds
        ]) {
            accountIdByServiceAppointmentId.put(sa.Id, sa.AccountId);
        }
        return AccountIdByServiceAppointmentId;
    }

    public static void recalculateManualSharing(List<ServiceAppointment> records) {
        Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>(records);
        List<ServiceAppointmentShare> serviceAppointmentShares = [
            SELECT Id, UserOrGroupId, ParentId
            FROM ServiceAppointmentShare
            WHERE ParentId IN :serviceAppointmentMap.keySet() AND RowCause = 'Manual'
        ];
        List<ServiceAppointmentShare> sharesToBeDeleted = new List<ServiceAppointmentShare>();
        for (ServiceAppointmentShare share : serviceAppointmentShares) {
            if (
                share.UserOrGroupId !=
                serviceAppointmentMap.get(share.ParentId).HOT_ServiceResource__r.RelatedRecordId ||
                serviceAppointmentMap.get(share.ParentId).HOT_DelPol_IsHideRecord__c
            ) {
                sharesToBeDeleted.add(share);
            }
        }
        try {
            delete sharesToBeDeleted;
        } catch (Exception e) {
            handleException(e);
        }
        for (ServiceAppointment serviceAppointment : serviceAppointmentMap.values()) {
            serviceAppointment.HOT_IsRecalculateManualSharing__c = false;
        }
        try {
            update serviceAppointmentMap.values();
        } catch (Exception e) {
            handleException(e);
        }
    }

    @future
    public static void removeAccessForHiddenServiceAppointments(Set<Id> serviceAppointmentIds) {
        if (serviceAppointmentIds == null || serviceAppointmentIds.isEmpty())
            return;

        try {
            Map<Id, Id> woBySa = getWorkOrderIds(new List<Id>(serviceAppointmentIds));
            Set<Id> workOrderIds = new Set<Id>();
            for (Id saId : woBySa.keySet()) {
                Id woId = woBySa.get(saId);
                if (woId != null)
                    workOrderIds.add(woId);
            }

            Map<Id, Id> accountBySa = getAccountIdByServiceAppointmentId(new List<Id>(serviceAppointmentIds));
            Set<Id> accountIds = new Set<Id>();
            for (Id saId : accountBySa.keySet()) {
                Id accId = accountBySa.get(saId);
                if (accId != null)
                    accountIds.add(accId);
            }

            List<ServiceAppointmentShare> saSharesToDelete = new List<ServiceAppointmentShare>();
            if (!serviceAppointmentIds.isEmpty()) {
                saSharesToDelete = [
                    SELECT Id
                    FROM ServiceAppointmentShare
                    WHERE RowCause = 'Manual' AND ParentId IN :serviceAppointmentIds
                ];
            }

            List<WorkOrderShare> woSharesToDelete = new List<WorkOrderShare>();
            if (!workOrderIds.isEmpty()) {
                woSharesToDelete = [
                    SELECT Id
                    FROM WorkOrderShare
                    WHERE RowCause = 'Manual' AND ParentId IN :workOrderIds
                ];
            }

            Map<Id, ServiceAppointment> hiddenSAs = new Map<Id, ServiceAppointment>(
                [
                    SELECT Id, AccountId, HOT_ServiceResource__r.RelatedRecordId
                    FROM ServiceAppointment
                    WHERE Id IN :serviceAppointmentIds
                ]
            );

            Set<String> hiddenAccountUserPairs = new Set<String>();
            Set<Id> hiddenUserIds = new Set<Id>();
            for (ServiceAppointment sa : hiddenSAs.values()) {
                if (
                    sa.AccountId != null &&
                    sa.HOT_ServiceResource__r != null &&
                    sa.HOT_ServiceResource__r.RelatedRecordId != null
                ) {
                    Id uid = sa.HOT_ServiceResource__r.RelatedRecordId;
                    hiddenUserIds.add(uid);
                    hiddenAccountUserPairs.add(String.valueOf(sa.AccountId) + ':' + String.valueOf(uid));
                }
            }

            Set<Id> visibleSAAccountIds = new Set<Id>(accountIds);
            Set<Id> visibleSAIds = new Set<Id>();
            Map<Id, ServiceAppointment> visibleSAsById = new Map<Id, ServiceAppointment>();
            if (!visibleSAAccountIds.isEmpty()) {
                for (ServiceAppointment visSa : [
                    SELECT Id, AccountId, HOT_ServiceResource__r.RelatedRecordId, HOT_DelPol_IsHideRecord__c
                    FROM ServiceAppointment
                    WHERE AccountId IN :visibleSAAccountIds AND HOT_DelPol_IsHideRecord__c = FALSE
                ]) {
                    visibleSAsById.put(visSa.Id, visSa);
                    visibleSAIds.add(visSa.Id);
                }
            }

            Map<Id, Set<Id>> shareUsersByVisibleSA = new Map<Id, Set<Id>>();
            if (!visibleSAIds.isEmpty()) {
                for (ServiceAppointmentShare share : [
                    SELECT Id, ParentId, UserOrGroupId
                    FROM ServiceAppointmentShare
                    WHERE RowCause = 'Manual' AND ParentId IN :visibleSAIds
                ]) {
                    if (!shareUsersByVisibleSA.containsKey(share.ParentId)) {
                        shareUsersByVisibleSA.put(share.ParentId, new Set<Id>());
                    }
                    shareUsersByVisibleSA.get(share.ParentId).add(share.UserOrGroupId);
                }
            }

            Set<String> accountUserPairsToKeep = new Set<String>();
            for (ServiceAppointment visSa : visibleSAsById.values()) {
                Id assignedUser = (visSa.HOT_ServiceResource__r != null)
                    ? visSa.HOT_ServiceResource__r.RelatedRecordId
                    : null;
                if (visSa.AccountId != null && assignedUser != null) {
                    Set<Id> shareUsers = shareUsersByVisibleSA.get(visSa.Id);
                    if (shareUsers != null && shareUsers.contains(assignedUser)) {
                        accountUserPairsToKeep.add(
                            String.valueOf(visSa.AccountId) + ':' + String.valueOf(assignedUser)
                        );
                    }
                }
            }

            List<AccountShare> accountSharesToDelete = new List<AccountShare>();
            if (!accountIds.isEmpty() && !hiddenUserIds.isEmpty()) {
                List<AccountShare> candidateAccountShares = [
                    SELECT Id, AccountId, UserOrGroupId
                    FROM AccountShare
                    WHERE RowCause = 'Manual' AND AccountId IN :accountIds AND UserOrGroupId IN :hiddenUserIds
                ];
                for (AccountShare accShare : candidateAccountShares) {
                    String key = String.valueOf(accShare.AccountId) + ':' + String.valueOf(accShare.UserOrGroupId);
                    if (hiddenAccountUserPairs.contains(key) && !accountUserPairsToKeep.contains(key)) {
                        accountSharesToDelete.add(accShare);
                    }
                }
            }

            if (!saSharesToDelete.isEmpty())
                delete saSharesToDelete;
            if (!woSharesToDelete.isEmpty())
                delete woSharesToDelete;
            if (!accountSharesToDelete.isEmpty())
                delete accountSharesToDelete;
        } catch (Exception e) {
            handleException(e);
        }
    }
}
