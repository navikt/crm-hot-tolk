public without sharing class HOT_ThreadHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Map<Id, Thread__c> threadByRequestId = new Map<Id, Thread__c>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' && thread.HOT_Request__c != null) {
                threadByRequestId.put(thread.HOT_Request__c, thread);
            }
        }
        if (!threadByRequestId.isEmpty()) {
            setDefaultFields(threadByRequestId);
        }
    }
    public override void onAfterInsert() {
        Map<Id, Id> threadIdByRequestId = new Map<Id, Id>();
        for (Thread__c thread : (List<Thread__c>) records) {
            if (thread.CRM_Type__c == 'HOT_BRUKER-FORMIDLER' && thread.HOT_Request__c != null) {
                threadIdByRequestId.put(thread.HOT_Request__c, thread.Id);
            }
        }
        if (!threadIdByRequestId.isEmpty()) {
            setLookupOnRequest(threadIdByRequestId);
        }
    }

    private static void setDefaultFields(Map<Id, Thread__c> threadByRequestId) {
        List<HOT_Request__c> requests = [
            SELECT Id, OwnerId, Subject__c
            FROM HOT_Request__c
            WHERE Id IN :threadByRequestId.keySet()
        ];
        for (HOT_Request__c request : requests) {
            threadByRequestId.get(request.Id).OwnerId = request.OwnerId;
            threadByRequestId.get(request.Id).Name = request.Subject__c;
        }
    }

    private static void setLookupOnRequest(Map<Id, Id> threadIdByRequestId) {
        List<HOT_Request__c> requestsToUpdate = new List<HOT_Request__c>();
        for (Id requestId : threadIdByRequestId.keySet()) {
            requestsToUpdate.add(new HOT_Request__c(Id = requestId, Thread__c = threadIdByRequestId.get(requestId)));
        }
        HOT_DatabaseOperations.updateRecords(requestsToUpdate);
    }
}
