public without sharing class HOT_DuplicateHandler {
    public static List<String> statuses = new List<String>{ 'New', 'Scheduled', 'Dispatched' };

    @AuraEnabled
    public static List<HOT_Request__c> getOverlappingRecordsFromRequestId(Id accountId, Id requestId) {
        HOT_Request__c request = [
            SELECT Id, (SELECT Id, StartDate, EndDate FROM HOT_Request__c.Work_Orders__r WHERE Status IN :statuses)
            FROM HOT_Request__c
            WHERE Id = :requestId
        ];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        for (WorkOrder workOrder : request.Work_Orders__r) {
            Map<String, Datetime> tempDatetimes = new Map<String, Datetime>();
            tempDatetimes.put('StartDate', workOrder.StartDate);
            tempDatetimes.put('EndDate', workOrder.EndDate);
            workOrderDatetimes.put(workOrder.Id, tempDatetimes);
        }

        Set<Id> requestIds = getOverlappingRecords(accountId, workOrderDatetimes, true).keySet();
        return [SELECT Id, Name FROM HOT_Request__c WHERE Id IN :requestIds];
    }

    @AuraEnabled
    public static List<WorkOrder> getOverlappingRecordsFromWorkOrderId(Id accountId, Id workOrderId) {
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        Map<String, Datetime> tempDatetimes = new Map<String, Datetime>();
        tempDatetimes.put('StartDate', workOrder.StartDate);
        tempDatetimes.put('EndDate', workOrder.EndDate);
        workOrderDatetimes.put(workOrder.Id, tempDatetimes);

        Set<Id> workOrderIds = getOverlappingRecords(accountId, workOrderDatetimes, false).keySet();
        return [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id IN :workOrderIds];
    }

    @AuraEnabled
    public static List<HOT_Request__c> checkDuplicates(Id accountId, Map<String, Map<String, Long>> times) {
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        for (String timesId : times.keySet()) {
            Map<String, Datetime> tempDatetime = new Map<String, Datetime>();
            tempDatetime.put('StartDate', Datetime.newInstance(times.get(timesId).get('startTime')));
            tempDatetime.put('EndDate', Datetime.newInstance(times.get(timesId).get('endTime')));

            workOrderDatetimes.put(timesId, tempDatetime);
        }
        Set<Id> requestIds = getOverlappingRecords(accountId, workOrderDatetimes, true).keySet();
        return [SELECT Id, Name, Subject__c, SeriesPeriod__c FROM HOT_Request__c WHERE Id IN :requestIds];
    }

    public static Map<Id, String> getOverlappingRecords(
        Id accountId,
        Map<String, Map<String, Datetime>> workOrderDatetimes,
        Boolean isRequestLevel
    ) {
        List<WorkOrder> workOrders = [
            SELECT Id, StartDate, EndDate, HOT_Request__c, HOT_Request__r.Name
            FROM WorkOrder
            WHERE AccountId = :accountId AND AccountId != NULL AND Status IN :statuses
        ];
        Map<Id, String> result = new Map<Id, String>();
        for (WorkOrder workOrder : workOrders) {
            for (String dateTimeId : workOrderDatetimes.keySet()) {
                DateTime aStart = workOrder.StartDate;
                DateTime aEnd = workOrder.EndDate;
                DateTime bStart = workOrderDatetimes.get(dateTimeId).get('StartDate');
                DateTime bEnd = workOrderDatetimes.get(dateTimeId).get('EndDate');
                if (
                    dateTimeId != (String) workOrder.Id &&
                    HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd)
                ) {
                    if (isRequestLevel && !result.keySet().contains(workOrder.HOT_Request__c)) {
                        result.put(workOrder.HOT_Request__c, dateTimeId);
                    } else {
                        result.put(workOrder.Id, dateTimeId);
                    }
                }
            }
        }
        return result;
    }
}
