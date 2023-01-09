@isTest
private class HOT_RequestListControllerTest {
    @testSetup
    static void setup() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (admin.UserRoleId == null) {
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
            admin.UserRoleId = role.Id;
            update admin;
        }
    }

    @isTest
    private static void getRequestListTest() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;
        Person__c person2 = HOT_TestDataFactory.createPerson();
        insert person2;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE CRM_Person__c = :person.Id
        ];
        Account account2 = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE CRM_Person__c = :person2.Id
        ];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Subject 2', workType);
        request2.Account__c = account2.Id;
        request2.Orderer__c = account.Id;
        request2.StartTime__c = request2.StartTime__c.addDays(-8);
        request2.EndTime__c = request2.EndTime__c.addDays(-8);
        insert request2;
        HOT_Request__c request3 = HOT_TestDataFactory.createRequest('Subject 3', workType);
        request3.Account__c = account2.Id;
        request3.Orderer__c = account.Id;
        request3.StartTime__c = request3.StartTime__c.addDays(-8);
        request3.EndTime__c = request3.EndTime__c.addDays(-8);
        insert request3;
        request3.Status__c = 'Godkjent';
        update request3;

        Test.startTest();
        Profile communityProfile = [
            SELECT Name
            FROM Profile
            WHERE Name = 'Personbruker Login' OR Name = 'Trial Customer Portal User' OR Name = 'Customer Community User'
            LIMIT 1
        ];
        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        Test.stopTest();

        System.runAs(user) {
            List<HOT_Request__c> requests = HOT_RequestListController.getRequestList();
            System.assertEquals(3, requests.size(), 'Could not get my requests');
        }
        List<HOT_Request__c> requests = HOT_RequestListController.getRequestList();
        System.assertEquals(null, requests, 'Falsly fetched requests');
    }

    @isTest
    private static void getTimesTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Hot_request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        List<Map<String, String>> times = HOT_RequestListController.getTimes(new List<String>{ (String) request.Id });
        System.assertEquals(1, times.size(), 'Could not get times');
    }

    @isTest
    private static void uploadFileTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Hot_request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;
        Map<String, String> files = new Map<String, String>();
        files.put('base64test', 'filename');

        HOT_RequestListController.uploadFile(files, request.Id);
        List<ContentDocumentLink> file = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :request.Id
        ];
        Boolean hasFile = file.size() > 0;
        System.assertEquals(true, hasFile, 'File was not uploaded');
    }
    @isTest
    private static void updateRelatedWorkOrdersCancel() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        List<WorkOrder> workOrders = new List<WorkOrder>();

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.StartDate = workOrder.StartDate.addDays(-10);
        workOrder.EndDate = workOrder.EndDate.addDays(-10);
        workOrders.add(workOrder);

        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder1.StartDate = workOrder1.StartDate.addDays(1);
        workOrder1.EndDate = workOrder1.EndDate.addDays(1);
        workOrders.add(workOrder1);

        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder2.StartDate = workOrder2.StartDate.addDays(2);
        workOrder2.EndDate = workOrder2.EndDate.addDays(2);
        workOrders.add(workOrder2);

        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder3.StartDate = workOrder3.StartDate.addDays(3);
        workOrder3.EndDate = workOrder3.EndDate.addDays(3);
        workOrders.add(workOrder3);

        insert workOrders;

        Test.startTest();
        HOT_RequestListController.updateRelatedWorkOrders(request.Id);
        List<WorkOrder> workOrdersCancelled = [SELECT Id, Status FROM WorkOrder WHERE Status = 'Canceled'];
        Test.stopTest();

        System.assertEquals(workOrdersCancelled.size(), 3, 'Ikke riktig avlyst');
    }
}
