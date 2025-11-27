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
            Map<Id, Id> woBySA = HOT_ServiceAppointmentsSharingService.getWorkOrderIds(new List<Id>(scopesaIds));
            Set<Id> woIds = new Set<Id>();
            for (Id saId : woBySA.keySet()) {
                if (woBySA.get(saId) != null)
                    woIds.add(woBySA.get(saId));
            }

            Map<Id, Id> accBySa = HOT_ServiceAppointmentsSharingService.getAccountIdByServiceAppointmentId(
                new List<Id>(scopesaIds)
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

            // --- Hidden SA Data ---
            Map<Id, ServiceAppointment> hiddenSAs = new Map<Id, ServiceAppointment>(
                [
                    SELECT Id, AccountId, HOT_ServiceResource__r.RelatedRecordId
                    FROM ServiceAppointment
                    WHERE Id IN :scopesaIds
                ]
            );

            Set<String> hiddenPairs = new Set<String>();
            Set<Id> hiddenUserIds = new Set<Id>();
            for (ServiceAppointment sa : hiddenSAs.values()) {
                if (
                    sa.AccountId != null &&
                    sa.HOT_ServiceResource__r != null &&
                    sa.HOT_ServiceResource__r.RelatedRecordId != null
                ) {
                    Id uid = sa.HOT_ServiceResource__r.RelatedRecordId;
                    hiddenUserIds.add(uid);
                    hiddenPairs.add(sa.AccountId + ':' + uid);
                }
            }

            // --- Visible SAs & Their Shares ---
            Map<Id, ServiceAppointment> visibleSAs = new Map<Id, ServiceAppointment>();
            Set<Id> visiblesaIds = new Set<Id>();

            if (!accountIds.isEmpty()) {
                for (ServiceAppointment visSa : [
                    SELECT Id, AccountId, HOT_ServiceResource__r.RelatedRecordId, HOT_DelPol_IsHideRecord__c
                    FROM ServiceAppointment
                    WHERE AccountId IN :accountIds AND HOT_DelPol_IsHideRecord__c = FALSE
                ]) {
                    visibleSAs.put(visSa.Id, visSa);
                    visiblesaIds.add(visSa.Id);
                }
            }

            Map<Id, Set<Id>> visibleSaSharedUsers = new Map<Id, Set<Id>>();
            if (!visiblesaIds.isEmpty()) {
                for (ServiceAppointmentShare share : [
                    SELECT ParentId, UserOrGroupId
                    FROM ServiceAppointmentShare
                    WHERE RowCause = 'Manual' AND ParentId IN :visiblesaIds
                ]) {
                    visibleSaSharedUsers.putIfAbsent(share.ParentId, new Set<Id>());
                    visibleSaSharedUsers.get(share.ParentId).add(share.UserOrGroupId);
                }
            }

            // --- Determine account-user pairs to keep ---
            Set<String> keepPairs = new Set<String>();
            for (ServiceAppointment vis : visibleSAs.values()) {
                Id uid = (vis.HOT_ServiceResource__r != null) ? vis.HOT_ServiceResource__r.RelatedRecordId : null;

                if (vis.AccountId != null && uid != null) {
                    if (visibleSaSharedUsers.containsKey(vis.Id) && visibleSaSharedUsers.get(vis.Id).contains(uid)) {
                        keepPairs.add(vis.AccountId + ':' + uid);
                    }
                }
            }

            // --- Account shares to delete ---
            List<AccountShare> accSharesToDelete = new List<AccountShare>();
            if (!accountIds.isEmpty() && !hiddenUserIds.isEmpty()) {
                List<AccountShare> candidates = [
                    SELECT Id, AccountId, UserOrGroupId
                    FROM AccountShare
                    WHERE RowCause = 'Manual' AND AccountId IN :accountIds AND UserOrGroupId IN :hiddenUserIds
                ];

                for (AccountShare s : candidates) {
                    String key = s.AccountId + ':' + s.UserOrGroupId;
                    if (hiddenPairs.contains(key) && !keepPairs.contains(key)) {
                        accSharesToDelete.add(s);
                    }
                }
            }

            // --- Perform Deletes ---
            if (!saSharesToDelete.isEmpty())
                delete saSharesToDelete;
            if (!woSharesToDelete.isEmpty())
                delete woSharesToDelete;
            if (!accSharesToDelete.isEmpty())
                delete accSharesToDelete;

            // --- Mark processed SAs ---
            List<ServiceAppointment> updates = new List<ServiceAppointment>();
            for (ServiceAppointment sa : scope) {
                sa.HOT_DelPol_ProcessedHidden__c = true;
                updates.add(sa);
            }
            update updates;
        } catch (Exception ex) {
            YourUtilityClass.handleException(ex);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
