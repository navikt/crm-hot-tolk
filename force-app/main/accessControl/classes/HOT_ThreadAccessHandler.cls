public without sharing class HOT_ThreadAccessHandler extends MyTriggers {
    public override void onAfterInsert() {
        Map<Id, Set<Id>> participantsByThread = new Map<Id, Set<Id>>();

        for (Thread__c thread : [
            SELECT Id, HOT_Participants__c
            FROM Thread__c
            WHERE
                Id IN :records
                AND (CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
                OR CRM_Thread_Type__c = 'HOT_TOLK-TOLK'
                OR CRM_Thread_Type__c = 'HOT_TOLK-BRUKER')
        ]) {
            if (thread.HOT_Participants__c.length() > 0) {
                Set<Id> participants = HOT_ThreadSharingService.populateParticipantSet(thread.HOT_Participants__c);
                participantsByThread.put(thread.Id, participants);
            }
        }

        HOT_ThreadSharingService.grantAccess(participantsByThread);
    }
}
