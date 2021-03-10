public without sharing class HOT_RequestListContoller {
    @AuraEnabled(cacheable=true)
    public static List<HOT_Request__c> getRequestList() {
        Id userId = UserInfo.getUserId();
        User user = [SELECT Id, AccountId, Name FROM User WHERE Id = :userId];
        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        if (user.AccountId != null) {
            List<HOT_Request__c> tempRequests = [
                SELECT
                    Name,
                    Subject__c,
                    StartTime__c,
                    EndTime__c,
                    MeetingStreet__c,
                    MeetingPostalCode__c,
                    NumberOfWorkOrders__c,
                    AdditionalInvoicetext__c,
                    MeetingPostalCity__c,
                    InterpretationStreet__c,
                    InterpretationPostalCode__c,
                    InterpretationPostalCity__c,
                    IsSerieoppdrag__c,
                    InvoiceReference__c,
                    Description__c,
                    Status__c,
                    ExternalRequestStatus__c,
                    Account__c,
                    EconomicalProvider__c,
                    ActualUserName__c,
                    TempAccountId__c,
                    OrganizationNumber__c,
                    Source__c,
                    Type__c,
                    toLabel(EventType__c),
                    Orderer__r.Name,
                    Orderer__c,
                    OrdererPhone__c,
                    OrdererEmail__c,
                    OrdererName__c,
                    Owner.Name,
                    UserName__c,
                    Company__r.Name,
                    (SELECT ServiceAppointment.HOT_ServiceResource__r.Name FROM HOT_Request__c.ServiceAppointments__r),
                    (
                        SELECT StartDate, EndDate
                        FROM HOT_Request__c.Work_Orders__r
                        WHERE Status != 'Annul'
                        ORDER BY StartDate
                    )
                FROM HOT_Request__c
                WHERE Account__c = :user.AccountId OR Orderer__c = :user.AccountId
                ORDER BY StartTime__c ASC
            ];

            //Setting the helping-field to control the users access to row-actions in requestList (lwc)
            //Hiding Users Name if the request happened 1 week ago
            DateTime oneWeekAgo = DateTime.now().addDays(-7);
            DateTime sixMonthsAgo = DateTime.now().addMonths(-6);
            for (HOT_Request__c request : tempRequests) {
                request.UserName__c = request.ActualUserName__c;
                request.TempAccountId__c = user.AccountId;
                if (request.NumberOfWorkOrders__c == 0 || request.NumberOfWorkOrders__c == null) {
                    request.NumberOfWorkOrders__c = 1;
                }
                if (request.Orderer__c == null) {
                    request.OrdererName__c = request.Owner.Name;
                } else {
                    request.OrdererName__c = request.Orderer__r.Name;
                }
                if (request.Account__c != user.AccountId) {
                    Integer numberOfWorkOrders = request.Work_Orders__r.size();
                    if (numberOfWorkOrders > 0) {
                        if (request.Work_Orders__r[numberOfWorkOrders - 1].StartDate < oneWeekAgo) {
                            request.UserName__c = '';
                        }
                        if (request.Work_Orders__r[numberOfWorkOrders - 1].StartDate > sixMonthsAgo) {
                            requests.add(request);
                        }
                    } else {
                        if (request.StartTime__c < oneWeekAgo) {
                            request.UserName__c = '';
                        }
                        if (request.StartTime__c > sixMonthsAgo) {
                            requests.add(request);
                        }
                    }
                } else {
                    requests.add(request);
                }
            }
        } else {
            requests = null;
        }

        return requests;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTimes(List<String> requestIds) {
        List<Map<String, String>> times = new List<Map<String, String>>();
        List<WorkOrder> workOrders = [
            SELECT Id, StartDate, EndDate, Status
            FROM WorkOrder
            WHERE HOT_Request__r.Id IN :requestIds AND Status != 'Annul' AND Status != 'Canceled'
            ORDER BY StartDate ASC
        ];
        for (WorkOrder workOrder : workOrders) {
            Map<String, String> timeMap = new Map<String, String>();
            timeMap.put('id', (String) workOrder.Id);
            Date tempDate = workOrder.StartDate.date();
            timeMap.put('date', Datetime.newInstance(tempDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd'));
            timeMap.put('startTime', String.valueOf(workOrder.StartDate.time()).removeEnd('Z'));
            timeMap.put('endTime', String.valueOf(workOrder.EndDate.time()).removeEnd('Z'));
            timeMap.put('status', workOrder.Status);
            times.add(timeMap);
        }
        return times;
    }
}
