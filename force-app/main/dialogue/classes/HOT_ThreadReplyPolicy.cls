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

        List<Thread__c> threads = [
            SELECT Id, CRM_Thread_Type__c, HOT_Close_DateTime__c, HOT_Request__c, HOT_Request__r.IsSerieoppdrag__c
            FROM Thread__c
            WHERE Id IN :validThreadIds
        ];

        Map<Id, Datetime> seriesEndTimeByRequestId = getSeriesEndTimeByRequestId(threads);

        for (Thread__c thread : threads) {
            result.put(thread.Id, buildPolicy(thread, seriesEndTimeByRequestId));
        }

        return result;
    }

    private static Map<Id, Datetime> getSeriesEndTimeByRequestId(List<Thread__c> threads) {
        Set<Id> seriesRequestIds = new Set<Id>();
        for (Thread__c thread : threads) {
            if (
                thread.CRM_Thread_Type__c != RESOURCE_OFFICE_THREAD_TYPE &&
                thread.HOT_Request__c != null &&
                thread.HOT_Request__r.IsSerieoppdrag__c == true
            ) {
                seriesRequestIds.add(thread.HOT_Request__c);
            }
        }

        Map<Id, Datetime> endTimeByRequestId = new Map<Id, Datetime>();
        if (seriesRequestIds.isEmpty()) {
            return endTimeByRequestId;
        }

        for (AggregateResult result : [
            SELECT HOT_Request__c requestId, MAX(SchedEndTime) maxScheduledEndTime, MAX(DueDate) maxDueDate
            FROM ServiceAppointment
            WHERE HOT_Request__c IN :seriesRequestIds AND Status NOT IN ('Annul', 'Canceled')
            GROUP BY HOT_Request__c
        ]) {
            Datetime maxScheduledEndTime = (Datetime) result.get('maxScheduledEndTime');
            Datetime maxDueDate = (Datetime) result.get('maxDueDate');
            endTimeByRequestId.put((Id) result.get('requestId'), laterOf(maxScheduledEndTime, maxDueDate));
        }

        return endTimeByRequestId;
    }

    private static Datetime laterOf(Datetime firstValue, Datetime secondValue) {
        if (firstValue == null) {
            return secondValue;
        }
        if (secondValue == null) {
            return firstValue;
        }
        return firstValue > secondValue ? firstValue : secondValue;
    }

    private static ReplyPolicy buildPolicy(Thread__c thread, Map<Id, Datetime> seriesEndTimeByRequestId) {
        if (thread.CRM_Thread_Type__c == RESOURCE_OFFICE_THREAD_TYPE) {
            return new ReplyPolicy(thread.Id, true, null, null);
        }

        Datetime endTime = getThreadEndTime(thread, seriesEndTimeByRequestId);
        if (endTime == null) {
            return new ReplyPolicy(thread.Id, true, null, null);
        }

        Datetime replyClosedAt = endTime.addHours(REPLY_WINDOW_HOURS);
        return new ReplyPolicy(thread.Id, System.now() < replyClosedAt, replyClosedAt, endTime);
    }

    private static Datetime getThreadEndTime(Thread__c thread, Map<Id, Datetime> seriesEndTimeByRequestId) {
        if (
            thread.HOT_Request__c != null &&
            thread.HOT_Request__r.IsSerieoppdrag__c == true &&
            seriesEndTimeByRequestId.containsKey(thread.HOT_Request__c)
        ) {
            return seriesEndTimeByRequestId.get(thread.HOT_Request__c);
        }

        return thread.HOT_Close_DateTime__c;
    }
}
