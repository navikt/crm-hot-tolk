public without sharing class HOT_RequestListContoller {

    @AuraEnabled(cacheable = true)
    public static List<HOT_Request__c> getRequestList() {
        Id userId = UserInfo.getUserId();
        User user = [SELECT Id, AccountId, Name FROM User WHERE Id = : userId];
        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        if(user.AccountId != null){
//            requests = [SELECT Name, Subject__c, StartTime__c, EndTime__c, MeetingStreet__c, MeetingPostalCode__c, NumberOfWorkOrders__c,
//            MeetingPostalCity__c, InterpretationStreet__c, InterpretationPostalCode__c, InterpretationPostalCity__c, IsSerieoppdrag__c,
//            Description__c, Status__c, ExternalRequestStatus__c, Account__c, (SELECT ServiceAppointment.HOT_ServiceResource__r.Name FROM HOT_Request__c.ServiceAppointments__r),
//            Source__c, Type__c, toLabel(EventType__c), Orderer__r.Name, OrdererPhone__c, OrdererEmail__c, UserName__c, UserPersonNumber__c, Company__r.Name, OrganizationNumber__c, InvoiceReference__c, AdditionalInvoicetext__c
//            ,EconomicalProvider__c, ActualUserName__c, TempAccountId__c
//            FROM HOT_Request__c WHERE Account__c = : user.AccountId OR Orderer__c = :user.AccountId ORDER BY StartTime__c ASC];
            requests = [SELECT Name, Subject__c, StartTime__c, EndTime__c, MeetingStreet__c, MeetingPostalCode__c, NumberOfWorkOrders__c,
            MeetingPostalCity__c, InterpretationStreet__c, InterpretationPostalCode__c, InterpretationPostalCity__c, IsSerieoppdrag__c, 
            Status__c, ExternalRequestStatus__c, Account__c, (SELECT ServiceAppointment.HOT_ServiceResource__r.Name FROM HOT_Request__c.ServiceAppointments__r),
            Source__c, Type__c, toLabel(EventType__c), Orderer__r.Name, OrdererPhone__c, OrdererEmail__c, UserName__c, UserPersonNumber__c, Company__r.Name, OrganizationNumber__c, InvoiceReference__c, AdditionalInvoicetext__c
            ,EconomicalProvider__c, ActualUserName__c, TempAccountId__c
            FROM HOT_Request__c WHERE Account__c = : user.AccountId OR Orderer__c = :user.AccountId ORDER BY StartTime__c ASC];
            //Setting the helping-field to control the users access to row-actions in requestList (lwc)
            for(HOT_Request__c request: requests){
                request.TempAccountId__c = user.AccountId;
                if(request.NumberOfWorkOrders__c == 0 || request.NumberOfWorkOrders__c == null){
                    request.NumberOfWorkOrders__c = 1;
                }
            }
        }
        else{
            requests = null;
        }
        
        return requests;
    }

    @AuraEnabled(cacheable = true)
    public static List<Map<String, String>> getTimes(List<String> requestIds) {
        List<Map<String, String>> times = new List<Map<String, String>>();
        List<WorkOrder> workOrders = [SELECT Id, StartDate, EndDate, Status FROM WorkOrder WHERE HOT_Request__r.Id IN :requestIds AND Status != 'Annul' AND Status != 'Canceled' ORDER BY StartDate ASC];
        for(WorkOrder workOrder:workOrders){
            Map<String, String> timeMap = new Map<String, String>();
            timeMap.put('id', (String) workOrder.Id);
            Date tempDate = workOrder.StartDate.date();
            timeMap.put('date', Datetime.newInstance(tempDate, Time.newInstance(0,0,0,0)).format('yyyy-MM-dd'));
            timeMap.put('startTime', String.valueOf(workOrder.StartDate.time()).removeEnd('Z'));
            timeMap.put('endTime', String.valueOf(workOrder.EndDate.time()).removeEnd('Z'));
            timeMap.put('status', workOrder.Status);
            times.add(timeMap);
        }
        return times;
    }


    @AuraEnabled(cacheable = true)
    public static List<HOT_Request__c> getRequestListFromAccountFromRequestId(Id recordId) {
        HOT_Request__c currentRecord = [SELECT Id, Name, Account__c FROM HOT_Request__c WHERE Id = :recordId];
        List<HOT_Request__c> requests = [SELECT Name, Id, StartTime__c, EndTime__c, Status__c, Account__c, ExternalRequestStatus__c
        FROM HOT_Request__c WHERE Account__c !=null AND Account__c = : currentRecord.Account__c];
        return requests;
    }
}