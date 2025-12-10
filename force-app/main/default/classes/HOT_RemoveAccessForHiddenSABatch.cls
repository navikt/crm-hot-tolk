public without sharing class HOT_RemoveAccessForHiddenSABatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_RemoveAccessForHiddenSABatch instance = new HOT_RemoveAccessForHiddenSABatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime today = Datetime.now();
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM ServiceAppointment
                WHERE
                    HOT_DelPol_IsHideRecord__c = TRUE
                    AND HOT_DelPol_ToHideRecord__c = TRUE
                    AND (HOT_DelPol_ProcessedHidden__c = FALSE
                    OR HOT_DelPol_ProcessedHidden__c = NULL)
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        Set<Id> saIds = new Set<Id>();
        for (ServiceAppointment sa : records) {
            saIds.add(sa.Id);
        }

        if (saIds.isEmpty())
            return;

        try {
            Map<Id, Id> woBySA = HOT_ServiceAppointmentsSharingService.getWorkOrderIds(new List<Id>(saIds));
            Set<Id> woIds = new Set<Id>();
            for (Id saId : woBySA.keySet()) {
                if (woBySA.get(saId) != null)
                    woIds.add(woBySA.get(saId));
            }

            Map<Id, Id> accBySa = HOT_ServiceAppointmentsSharingService.getAccountIdByServiceAppointmentId(
                new List<Id>(saIds)
            );
            Set<Id> accountIds = new Set<Id>();
            for (Id saId : accBySa.keySet()) {
                if (accBySa.get(saId) != null)
                    accountIds.add(accBySa.get(saId));
            }

            List<ServiceAppointmentShare> saSharesToDelete = [
                SELECT Id
                FROM ServiceAppointmentShare
                WHERE RowCause = 'Manual' AND ParentId IN :saIds
            ];

            List<WorkOrderShare> woSharesToDelete = (woIds.isEmpty())
                ? new List<WorkOrderShare>()
                : [
                      SELECT Id
                      FROM WorkOrderShare
                      WHERE RowCause = 'Manual' AND ParentId IN :woIds
                  ];

            Map<Id, ServiceAppointment> hiddenSAs = new Map<Id, ServiceAppointment>(
                [
                    SELECT Id, AccountId, HOT_ServiceResource__r.RelatedRecordId
                    FROM ServiceAppointment
                    WHERE Id IN :saIds
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

            Map<Id, ServiceAppointment> visibleSAsById = new Map<Id, ServiceAppointment>();
            Set<Id> visibleSAIds = new Set<Id>();

            if (!accountIds.isEmpty()) {
                for (ServiceAppointment visSA : [
                    SELECT Id, AccountId, HOT_ServiceResource__r.RelatedRecordId, HOT_DelPol_IsHideRecord__c
                    FROM ServiceAppointment
                    WHERE AccountId IN :accountIds AND HOT_DelPol_IsHideRecord__c = FALSE
                ]) {
                    visibleSAsById.put(visSA.Id, visSA);
                    visibleSAIds.add(visSA.Id);
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
            for (ServiceAppointment sa : visibleSAsById.values()) {
                Id uid = (sa.HOT_ServiceResource__r != null) ? sa.HOT_ServiceResource__r.RelatedRecordId : null;

                if (sa.AccountId != null && uid != null) {
                    if (shareUsersByVisibleSA.containsKey(sa.Id) && shareUsersByVisibleSA.get(sa.Id).contains(uid)) {
                        accountUserPairsToKeep.add(sa.AccountId + ':' + uid);
                    }
                }
            }

            List<AccountShare> accountSharesToDelete = new List<AccountShare>();
            if (!accountIds.isEmpty() && !hiddenUserIds.isEmpty()) {
                List<AccountShare> accShares = [
                    SELECT Id, AccountId, UserOrGroupId
                    FROM AccountShare
                    WHERE RowCause = 'Manual' AND AccountId IN :accountIds AND UserOrGroupId IN :hiddenUserIds
                ];

                for (AccountShare share : accShares) {
                    String key = share.AccountId + ':' + share.UserOrGroupId;
                    if (hiddenAccountUserPairs.contains(key) && !accountUserPairsToKeep.contains(key)) {
                        accountSharesToDelete.add(share);
                    }
                }
            }

            if (!saSharesToDelete.isEmpty())
                delete saSharesToDelete;
            if (!woSharesToDelete.isEmpty())
                delete woSharesToDelete;
            if (!accountSharesToDelete.isEmpty())
                delete accountSharesToDelete;

            List<ServiceAppointment> updates = new List<ServiceAppointment>();
            for (ServiceAppointment sa : records) {
                sa.HOT_DelPol_ProcessedHidden__c = true;
                updates.add(sa);
            }
            update updates;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(
                    new HOT_RemoveAccessForHiddenSABatch(),
                    'HOT_RemoveAccessForHiddenSABatch',
                    1440,
                    10
                );
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
