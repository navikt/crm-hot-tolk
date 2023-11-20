public without sharing class HOT_ThreadAccessHandler extends MyTriggers {
    public override void onAfterInsert() {
        Map<Id, Set<Id>> participantsByRelatedObject = new Map<Id, Set<Id>>();

        for (Thread__c thread : [SELECT Id, HOT_Participants FROM Thread__c WHERE Id IN :records]) {
            if (thread.HOT_Participants.length() > 0) {
                Set<Id> participantsOnThread = ThreadSharingService.populateParticipantSet(thread.HOT_Participants__c);
                participantsByRelatedObject.put(thread.Id, participantsOnThread);
            }
        }

        ThreadSharingService.grantAccess(participantsByRelatedObject);
    }
}
