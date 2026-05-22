public without sharing class HOT_ThreadReplyPolicy {
    private static final String RESOURCE_OFFICE_THREAD_TYPE = 'HOT_TOLK-RESSURSKONTOR';
    private static final Integer REPLY_WINDOW_HOURS = 48;

    public class ReplyPolicy {
        @AuraEnabled
        public Id threadId;
        @AuraEnabled
        public Boolean canReply;
        @AuraEnabled
        public Datetime replyClosedAt;
        @AuraEnabled
        public Datetime appointmentEndTime;

        public ReplyPolicy(Id threadId, Boolean canReply, Datetime replyClosedAt, Datetime appointmentEndTime) {
            this.threadId = threadId;
            this.canReply = canReply;
            this.replyClosedAt = replyClosedAt;
            this.appointmentEndTime = appointmentEndTime;
        }
    }

    public static void addErrorsForClosedThreads(List<Message__c> messages) {
        Set<Id> threadIds = new Set<Id>();
        for (Message__c message : messages) {
            if (message.CRM_Thread__c != null) {
                threadIds.add(message.CRM_Thread__c);
            }
        }
        if (threadIds.isEmpty()) {
            return;
        }

        Map<Id, ReplyPolicy> policiesByThreadId = getReplyPolicies(threadIds);
        for (Message__c message : messages) {
            ReplyPolicy policy = policiesByThreadId.get(message.CRM_Thread__c);
            if (policy != null && !policy.canReply) {
                message.addError('Denne samtalen er stengt for videre dialog.');
            }
        }
    }

    public static Map<Id, ReplyPolicy> getReplyPolicies(Set<Id> threadIds) {
        Map<Id, ReplyPolicy> result = new Map<Id, ReplyPolicy>();
        if (threadIds == null || threadIds.isEmpty()) {
            return result;
        }

        Set<Id> validThreadIds = new Set<Id>();
        for (Id threadId : threadIds) {
            if (threadId != null) {
                validThreadIds.add(threadId);
            }
        }

        if (validThreadIds.isEmpty()) {
            return result;
        }

        for (Thread__c thread : [
            SELECT Id, CRM_Thread_Type__c, HOT_Close_DateTime__c
            FROM Thread__c
            WHERE Id IN :validThreadIds
        ]) {
            result.put(thread.Id, buildPolicy(thread));
        }

        return result;
    }

    private static ReplyPolicy buildPolicy(Thread__c thread) {
        if (thread.CRM_Thread_Type__c == RESOURCE_OFFICE_THREAD_TYPE) {
            return new ReplyPolicy(thread.Id, true, null, null);
        }

        Datetime endTime = thread.HOT_Close_DateTime__c;
        if (endTime == null) {
            return new ReplyPolicy(thread.Id, true, null, null);
        }

        Datetime replyClosedAt = endTime.addHours(REPLY_WINDOW_HOURS);
        return new ReplyPolicy(thread.Id, System.now() < replyClosedAt, replyClosedAt, endTime);
    }
}
