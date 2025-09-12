public without sharing class HOT_ThreadSharingService {
    public static void grantAccess(Map<Id, Set<Id>> interpreterByThread) {
        Set<Id> interpretersToGrantAccess = new Set<Id>();
        Set<Id> threadIds = interpreterByThread.keySet();
        List<Thread__Share> threadShares = new List<Thread__Share>();
        for (Id threadId : threadIds) {
            interpretersToGrantAccess = interpreterByThread.get(threadId);
            for (Id userId : interpretersToGrantAccess) {
                threadShares.add(
                    new Thread__Share(
                        ParentId = threadId,
                        AccessLevel = 'Edit',
                        RowCause = 'Manual',
                        UserOrGroupId = userId
                    )
                );
            }
        }
        new CRM_DatabaseOperations()
            .setNumberOfRetries(1)
            .setDomain(CRM_ApplicationDomain.Domain.HOT)
            .insertRecords(threadShares);
    }
    public static void revokeAccess(List<Thread__c> threads) {
        Set<Id> parentIdToDelete = new Map<Id, Thread__c>(threads).keySet();
        if (parentIdToDelete.size() > 0) {
            List<Thread__Share> toDelete = [
                SELECT Id
                FROM Thread__Share
                WHERE RowCause = 'Manual' AND ParentId IN :parentIdToDelete
            ];
            new CRM_DatabaseOperations()
                .setNumberOfRetries(1)
                .setDomain(CRM_ApplicationDomain.Domain.HOT)
                .deleteRecords(toDelete);
        }
    }

    public static Set<Id> populateParticipantSet(String participants) {
        Set<Id> participantSet = new Set<Id>();
        List<String> participantIds = participants.split(',');
        for (String participantId : participantIds) {
            participantSet.add(participantId.trim());
        }

        return participantSet;
    }
}
