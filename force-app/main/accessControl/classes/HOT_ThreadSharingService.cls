public without sharing class HOT_ThreadSharingService {
    public static void grantAccess(Map<Id, Set<Id>> interpreterByRelatedObject) {
    }

    public static Set<Id> populateParticipantSet(String participants) {
        Set<Id> participantSet = new Set<Id>();
        if (participants != null && participants.length() > 0) {
            List<String> participantIds = participants.split(',');
            for (String participantId : participantIds) {
                participantSet.add(participantId.trim());
            }
        }

        return participantSet;
    }
}
