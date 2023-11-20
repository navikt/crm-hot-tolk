public without sharing class HOT_ThreadAccessHandler extends MyTriggers {
    public override void onAfterInsert() {
        Map<Id, Set<Id>> participantsByThread = new Map<Id, Set<Id>>();

        for (Thread__c thread : [SELECT Id, HOT_Participants__c FROM Thread__c WHERE Id IN :records]) {
            if (thread.HOT_Participants__c.length() > 0) {
                Set<Id> participants = HOT_ThreadSharingService.populateParticipantSet(thread.HOT_Participants__c);
                participantsByThread.put(thread.Id, participants);
            }
        }

        HOT_ThreadSharingService.grantAccess(participantsByThread);
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        Map<Id, Set<Id>> participantsByThread = new Map<Id, Set<Id>>();

        for (Thread__c thread : [SELECT Id, HOT_Participants__c FROM Thread__c WHERE Id IN :records]) {
            if (thread.HOT_Participants__c.length() > 0) {
                Set<Id> participants = HOT_ThreadSharingService.populateParticipantSet(thread.HOT_Participants__c);
                participantsByThread.put(thread.Id, participants);
            }
        }

        HOT_ThreadSharingService.grantAccess(participantsByThread);
    }
}
