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

        Map<Id, Id> contentDocumentMap = new Map<Id, Id>();

        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :cvList
        ]) {
            contentDocumentMap.put(cv.Id, cv.ContentDocumentId);
        }

        for (ContentVersion cv : cvList) {
            ContentDocumentLink cdl = createContentDocumentLink(contentDocumentMap.get(cv.Id), recordId);

            if (cdl != null) {
                cdlList.add(cdl);
            }
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

    private static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, String recordId) {
        if (contentDocumentId == null || recordId == null) {
            return null;
        }

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
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

    @AuraEnabled(cacheable=true)
    public static List<Account> getOrganizationInfo(String organizationNumber) {
        List<Account> account = [
            SELECT Id, Name, INT_OrganizationNumber__c
            FROM Account
            WHERE INT_OrganizationNumber__c = :organizationNumber
        ];
        return account;
    }
}
