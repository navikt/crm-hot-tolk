public without sharing class HOT_DuplicateHandler {
    @AuraEnabled
    public static List<HOT_Request__c> getOverlappingRecordsFromRequestId(Id accountId, Id requestId) {
        HOT_Request__c request = [
            SELECT Id, (SELECT Id, StartDate, EndDate FROM HOT_Request__c.Work_Orders__r)
            FROM HOT_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        for (WorkOrder workOrder : request.Work_Orders__r) {
            Map<String, Datetime> tempDatetimes = new Map<String, Datetime>();
            tempDatetimes.put('StartDate', workOrder.StartDate);
            tempDatetimes.put('EndDate', workOrder.EndDate);
            workOrderDatetimes.put(workOrder.Id, tempDatetimes);
        }

        List<Id> requestIds = getOverlappingRecords(accountId, workOrderDatetimes, true).values();
        return [SELECT Id, Name FROM HOT_Request__c WHERE Id IN :requestIds];
    }

    @AuraEnabled
    public static Map<String, Id> getOverlappingRecords(
        Id accountId,
        Map<String, Map<String, Datetime>> workOrderDatetimes,
        Boolean isRequestLevel
    ) {
        List<String> statuses = new List<String>{ 'New', 'Scheduled', 'Dispatched', 'In Progress' };
        List<WorkOrder> workOrders = [
            SELECT Id, StartDate, EndDate, HOT_Request__c, HOT_Request__r.Name
            FROM WorkOrder
            WHERE AccountId = :accountId AND Status IN :statuses
        ];
        Map<String, Id> result = new Map<String, Id>();
        for (WorkOrder workOrder : workOrders) {
            for (String dateTimeId : workOrderDatetimes.keySet()) {
                if (
                    dateTimeId != (String) workOrder.Id &&
                    (workOrderDatetimes.get(dateTimeId).get('StartDate') > workOrder.StartDate &&
                    workOrderDatetimes.get(dateTimeId).get('StartDate') < workOrder.EndDate ||
                    workOrderDatetimes.get(dateTimeId).get('EndDate') > workOrder.StartDate &&
                    workOrderDatetimes.get(dateTimeId).get('EndDate') < workOrder.EndDate ||
                    workOrderDatetimes.get(dateTimeId).get('StartDate') <= workOrder.StartDate &&
                    workOrderDatetimes.get(dateTimeId).get('EndDate') >= workOrder.EndDate)
                ) {
                    if (isRequestLevel && !result.values().contains(workOrder.HOT_Request__c)) {
                        result.put(dateTimeId, workOrder.HOT_Request__c);
                    } else {
                        result.put(dateTimeId, workOrder.Id);
                    }
                }
            }
        }
        return result;
    }
}
