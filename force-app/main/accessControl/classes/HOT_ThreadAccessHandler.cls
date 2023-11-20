public without sharing class HOT_ThreadAccessHandler extends MyTriggers {
    public override void onAfterInsert() {
        Map<Id, Set<Id>> participantsByThread = new Map<Id, Set<Id>>();

        for (Thread__c thread : [SELECT Id, HOT_Participants__c FROM Thread__c WHERE Id IN :records]) {
            if (thread.HOT_Participants.length() > 0) {
                Set<Id> participants = HOT_ThreadSharingService.populateParticipantSet(thread.HOT_Participants__c);
                participantsByThread.put(thread.Id, participants);
            }
        }

        ThreadSharingService.grantAccess(participantsByRelatedObject);
    }
}
