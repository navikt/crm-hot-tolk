public without sharing class HOT_ThreadHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Map<Id, Thread__c> threadByRequestId = new Map<Id, Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' && thread.HOT_Request__c != null) {
                threadByRequestId.put(thread.HOT_Request__c, thread);
            }
        }
        if (!threadByRequestId.isEmpty()) {
            setThreadOwner(threadByRequestId);
        }
    }

    private static void setThreadOwner(Map<Id, Thread__c> threadByRequestId) {
        List<HOT_Request__c> requests = [
            SELECT Id, OwnerId
            FROM HOT_Request__c
            WHERE Id IN :threadByRequestId.keySet()
        ];
        for (HOT_Request__c request : requests) {
            threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
        }
    }
}
