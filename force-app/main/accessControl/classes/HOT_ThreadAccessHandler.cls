public without sharing class HOT_ThreadAccessHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<Thread__c> threadsToUpdate = new List<Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                new Set<String>{
                    'HOT_TOLK-FORMIDLER', 
                    'HOT_TOLK-TOLK', 
                    'HOT_BRUKER-TOLK', 
                    'HOT_TOLK-RESSURSKONTOR'
                }.contains(thread.CRM_Thread_Type__c)
                && MyTriggers.hasChangedFields(
                    new List<String>{'HOT_ParticipantIds__c'},
                    thread,
                    (Thread__c)triggerOldMap.get(thread.Id)
                )
            ) {
                threadsToUpdate.add(thread);
            }
        }

        if (threadsToUpdate.size() > 0) {
            HOT_ThreadSharingService.revokeAccess(threadsToUpdate);
            grantAccessToThreads(threadsToUpdate);
        }
    }

    public static void grantAccessToThreads(List<Thread__c> threads) {
        Map<Id, Set<Id>> participantsByThread = new Map<Id, Set<Id>>();

        for (Thread__c thread : threads) {
            if (thread.HOT_ParticipantIds__c != null && thread.HOT_ParticipantIds__c.length() > 0) {
                Set<Id> participants = HOT_ThreadSharingService.populateParticipantSet(thread.HOT_ParticipantIds__c);
                participantsByThread.put(thread.Id, participants);
            }
        }

        HOT_ThreadSharingService.grantAccess(participantsByThread);
    }
}
