public without sharing class HOT_ThreadAccessHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        Set<Id> threadIds = new Set<Id>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_TOLK-TOLK' ||
                thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK' ||
                thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR'
            ) {
                threadIds.add(thread.Id);
            }

            if (threadIds.size() > 0) {
                // grantAccessToThreads(threadIds);
            }
        }
    }

    @Future
    public static void grantAccessToThreads(Set<Id> threadIds) {
        Map<Id, Set<Id>> participantsByThread = new Map<Id, Set<Id>>();
        List<Thread__c> threads = [SELECT HOT_Participants__c FROM Thread__c WHERE Id IN :threadIds];

        for (Thread__c thread : threads) {
            if (thread.HOT_Participants__c != null && thread.HOT_Participants__c.length() > 0) {
                Set<Id> participants = HOT_ThreadSharingService.populateParticipantSet(thread.HOT_Participants__c);
                participantsByThread.put(thread.Id, participants);
            }
        }

        HOT_ThreadSharingService.grantAccess(participantsByThread);
    }
}
