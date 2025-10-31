@IsTest
private class HOT_RequestListControllerTest {
    @testSetup
    static void setup() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (admin.UserRoleId == null) {
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
            admin.UserRoleId = role.Id;
            update admin;
        }

        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'BrukerAddresseTest';
        person.INT_ResidentialAddress__c = 'Testveien 1';
        person.INT_ResidentialZipCode__c = '1234';
        insert person;

        Person__c person2 = HOT_TestDataFactory.createPerson();
        person2.INT_FirstName__c = 'Tolk2';
        person2.INT_LastName__c = 'BrukerAddresseTest2';
        person2.INT_ResidentialAddress__c = 'Testveien 2';
        person2.INT_ResidentialZipCode__c = '2234';
        insert person2;

        Account account = [
            SELECT Id, LastName, OwnerId, CRM_Person__c, PersonContactId
            FROM Account
            WHERE LastName = :person.INT_LastName__c
        ];
        account.OwnerId = admin.Id;
        update account;

        Account account2 = [
            SELECT Id, LastName, OwnerId, CRM_Person__c, PersonContactId
            FROM Account
            WHERE LastName = :person2.INT_LastName__c
        ];
        account2.OwnerId = admin.Id;
        update account2;

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;

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

        Common_Code__c commonCode = new Common_Code__c(
            Name = 'Test Postal Code',
            CRM_Active__c = true,
            CRM_Code_Set__c = 'Postnummer',
            CRM_Code__c = '8110',
            CRM_UniqueKey__c = 'Postnummer8110'
        );
        insert commonCode;
    }

    @IsTest
    private static void getRequestListTest() {
        System.debug('Kom hit');
        User user = [SELECT Id FROM User WHERE Username = 'HOT_testuser1@nav.hot.no' LIMIT 1];
        Test.startTest();
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'Subject 3' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        System.runAs(user) {
            List<HOT_Request__c> requests = HOT_RequestListController.getRequestList();
            System.assertEquals(3, requests.size(), 'Could not get my requests');
        }

        List<HOT_Request__c> requests = HOT_RequestListController.getRequestList();
        Test.stopTest();

        System.assertEquals(null, requests, 'Falsly fetched requests');
    }

    @IsTest
    private static void getTimesTest() {
        Test.startTest();
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'Subject 3' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;
        List<Map<String, String>> times = HOT_RequestListController.getTimes(new List<String>{ (String) request.Id });
        Test.stopTest();
        System.assertEquals(1, times.size(), 'Could not get times');
    }

    @IsTest
    private static void uploadFileTest() {
        Test.startTest();
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'Subject 3' LIMIT 1];
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
        Test.stopTest();
        System.assertEquals(true, hasFile, 'File was not uploaded');
    }
    @IsTest
    private static void updateRelatedWorkOrdersCancel() {
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
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
    @IsTest
    static void getThreadRequestIdTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = request.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        insert t;

        Test.startTest();
        String threadId = HOT_RequestListController.getThreadRequestId(request.Id, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();

        System.assertEquals(t.Id, threadId, 'Could not find the thread Id');
    }
    @IsTest
    static void getRequestStatusTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];

        Test.startTest();
        String status = HOT_RequestListController.getRequestStatus(request.Id);
        Test.stopTest();

        System.assertEquals('Åpen', status, 'Could not get correct status');
    }
    @IsTest
    static void testGetTimesNew() {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        Account account = [SELECT Id FROM Account LIMIT 1];
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];

        for (Integer i = 1; i <= 3; i++) {
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            workOrder.StartDate = DateTime.now().addDays(i);
            workOrder.EndDate = workOrder.StartDate.addHours(2);
            workOrder.Status = 'In Progress';
            workOrders.add(workOrder);
        }
        insert workOrders;

        Test.startTest();
        List<String> requestIds = new List<String>();
        for (WorkOrder wo : workOrders) {
            requestIds.add(wo.HOT_Request__c);
        }
        List<Map<String, String>> result = HOT_RequestListController.getTimesNew(requestIds);
        Test.stopTest();
        System.assertEquals(result.size(), 3);
        for (Integer i = 0; i < result.size(); i++) {
            Map<String, String> timeMap = result[i];
            WorkOrder wo = workOrders[i];
            System.assertEquals(timeMap.get('id'), wo.Id);
        }
    }

    @IsTest
    static void testGetPostalCity() {
        System.Test.startTest();
        List<Common_Code__c> result = HOT_RequestListController.getPostalCity('8110');
        System.Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Should return at least one record');
        System.assertEquals('Test Postal Code', result[0].Name, 'Expected postal city to match');
        System.assertEquals('8110', result[0].CRM_Code__c, 'Postal code should match');
    }

    @IsTest
    static void testGetPostalCityNotFound() {
        System.Test.startTest();
        List<Common_Code__c> result = HOT_RequestListController.getPostalCity('9999');
        System.Test.stopTest();

        System.assertEquals(0, result.size(), 'Expected no records for postalCode');
    }

    @IsTest
    static void testGetUserHomeAddress() {
        User user = [SELECT Id FROM User WHERE Alias = 'userTest' LIMIT 1];
        Person__c result;

        System.Test.startTest();

        System.runAs(user) {
            result = HOT_RequestListController.getUserHomeAddress();
        }
        System.Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a person record');
        System.assertEquals('Testveien 1', result.INT_ResidentialAddress__c, 'Expected address to match');
        System.assertEquals('1234', result.INT_ResidentialZipCode__c, 'Expected zip code to match');
    }

    @IsTest
    static void testGetUserHomeAddressEmptyPersons() {
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Person__c result;

        System.Test.startTest();

        System.runAs(user) {
            result = HOT_RequestListController.getUserHomeAddress();
        }
        System.Test.stopTest();

        System.assertEquals(null, result, 'Should return a person record');
    }
}
