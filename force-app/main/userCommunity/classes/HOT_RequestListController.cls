public without sharing class HOT_RequestListController {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    @AuraEnabled
    public static void uploadFile(Map<String, String> files, String recordId) {
        List<ContentVersion> cvList = new List<ContentVersion>();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (String base64 : files.keySet()) {
            cvList.add(createContentVersion(base64, files.get(base64)));
        }
        insertContentVersions(cvList);
        for (ContentVersion cv : cvList) {
            cdlList.add(createContentDocumentLink(cv.Id, recordId));
        }
        insertContentDocumentLinks(cdlList);
    }

    private static void insertContentDocumentLinks(List<ContentDocumentLink> cdlList) {
        try {
            insert cdlList;
        } catch (DMLException e) {
            handleException(e);
        }
    }

    private static void insertContentVersions(List<ContentVersion> cvList) {
        try {
            insert cvList;
        } catch (DMLException e) {
            handleException(e);
        }
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        return cv;
    }

    private static ContentDocumentLink createContentDocumentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) {
            return null;
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
        cdl.Visibility = 'AllUsers';
        return cdl;
    }

    @AuraEnabled(cacheable=true)
    public static String getRequestStatus(Id recordId) {
        return [SELECT Status__c FROM HOT_Request__c WHERE Id = :recordId]?.Status__c;
    }

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
                    SeriesEndDate__c,
                    MeetingStreet__c,
                    MeetingPostalCode__c,
                    MeetingPostalCity__c,
                    NumberOfWorkOrders__c,
                    AdditionalInvoicetext__c,
                    InterpretationStreet__c,
                    InterpretationPostalCode__c,
                    InterpretationPostalCity__c,
                    IsSerieoppdrag__c,
                    IsScreenInterpreter__c,
                    IsOtherEconomicProvicer__c,
                    IsOrdererWantStatusUpdateOnSMS__c,
                    InvoiceReference__c,
                    Description__c,
                    Status__c,
                    ExternalRequestStatus__c,
                    Account__c,
                    ActualUserName__c,
                    TempAccountId__c,
                    OrganizationNumber__c,
                    Source__c,
                    Type__c,
                    Orderer__r.Name,
                    Orderer__c,
                    OrdererPhone__c,
                    OrdererEmail__c,
                    OrdererName__c,
                    Owner.Name,
                    toLabel(AssignmentType__c),
                    UserName__c,
                    UserPhone__c,
                    UserPersonNumber__c,
                    UserPreferredInterpreter__c,
                    toLabel(UserInterpretationMethod__c),
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

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTimesNew(List<String> requestIds) {
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
            timeMap.put('startTime', String.valueOf(workOrder.StartDate.getTime()));
            timeMap.put('endTime', String.valueOf(workOrder.EndDate.getTime()));
            timeMap.put('status', workOrder.Status);
            times.add(timeMap);
        }
        return times;
    }
    @AuraEnabled
    public static void updateRelatedWorkOrders(String requestId) {
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        List<WorkOrder> workOrders = [
            SELECT Id, Status, StartDate, EndDate
            FROM WorkOrder
            WHERE HOT_Request__r.Id = :requestId
        ];
        for (WorkOrder workOrder : workOrders) {
            if (workOrder.StartDate > Datetime.now()) {
                workOrder.Status = 'Canceled';
                workOrdersToUpdate.add(workOrder);
            }
        }
        update workOrdersToUpdate;

        HOT_Request__c request = [SELECT IsNotifyDispatcher__c, Status__c FROM HOT_Request__c WHERE Id = :requestId];
        request.IsNotifyDispatcher__c = true;
        update request;
    }
    @AuraEnabled
    public static String getThreadRequestId(String requestId, String type) {
        List<Thread__c> thread = [
            SELECT Id
            FROM Thread__c
            WHERE CRM_Related_Object__c = :requestId AND CRM_Thread_Type__c = :type
            LIMIT 1
        ];
        String Id = '';
        if (thread.size() > 0) {
            Id = thread[0].Id;
        }
        return Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Common_Code__c> getPostalCity(String postalCode) {
        List<Common_Code__c> postalCommonCode = [
            SELECT CRM_Active__c, CRM_Code_Set__c, CRM_Code__c, Name, CRM_UniqueKey__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Postnummer' AND CRM_Active__c = TRUE AND CRM_Code__c = :postalCode
        ];
        return postalCommonCode;
    }

    @AuraEnabled(cacheable=true)
    public static Person__c getUserHomeAddress() {
        User currentUser = [
            SELECT Id, AccountId, Account.CRM_Person__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        List<Person__c> persons = [
            SELECT Id, INT_ResidentialAddress__c, INT_ResidentialZipCode__c
            FROM Person__c
            WHERE Id = :currentUser.Account.CRM_Person__c
            LIMIT 1
        ];

        if (persons.isEmpty()) {
            return null;
        }

        return persons[0];
    }
}
