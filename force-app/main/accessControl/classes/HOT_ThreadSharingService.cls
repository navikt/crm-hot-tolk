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
        try {
            insert threadShares;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
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
