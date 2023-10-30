@isTest
private class HOT_MessageHelperTest {
    @TestSetup
    static void makeData() {
        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = acc.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.CRM_Related_Object__c = request.Id;

        Thread__c t2 = HOT_TestDataFactory.createThread();
        t2.CRM_Related_Object__c = acc.Id;
        t2.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';

        Thread__c t3 = HOT_TestDataFactory.createThread();
        t3.CRM_Related_Object__c = acc.Id;
        t2.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';

        insert new List<Thread__c>{ t, t2, t3 };

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        insert m;
    }
    @isTest
    static void getObjectTypeFromidTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        String objectType = HOT_MessageHelper.getRecordObjectType(acclist.get(0).Id);
        Test.stopTest();
        System.assertEquals('Account', objectType, 'Object type is not recoginzed as expected');
    }
    @isTest
    static void getUserContactId() {
        Test.startTest();
        String contactId = HOT_MessageHelper.getUserContactId();
        Test.stopTest();
        System.assertEquals(null, contactId, 'User Contact Id was not returned correctly');
    }
    @isTest
    static void getAccountOnWorkOrder() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        Test.startTest();
        Id accountId = HOT_MessageHelper.getAccountOnWorkOrder(workOrder.Id);
        Test.stopTest();
        System.assertEquals(workOrder.AccountId, accountId, 'Account Id was not correct');
    }
    @isTest
    static void getRequestInformation() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        List<HOT_Request__c> requests = HOT_MessageHelper.getRequestInformation(request.Id);
        Boolean result = requests[0].IsAccountEqualOrderer__c;
        Test.stopTest();
        System.assertEquals(result, true, 'Account Id was not correct');
    }
    @isTest
    static void getWorkOrderInformation() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        List<WorkOrder> wo = HOT_MessageHelper.getWorkOrderInformation(workOrder.Id);
        String result = String.valueOf(wo[0].HOT_TotalNumberOfInterpreters__c);
        Test.stopTest();
        System.assertEquals(result, '0', 'Did not find correct number of interpreters');
    }
    @isTest
    static void getThreadsCollectionThread() {
        Thread__c t = [SELECT Id FROM Thread__c WHERE CRM_Type__c = 'HOT_BRUKER-FORMIDLER' LIMIT 1];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(t.Id, true, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(1, resList.size());
    }
    @isTest
    static void getThreadsCollectionSingleTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(
            accList.get(0).Id,
            true,
            'HOT_BRUKER-FORMIDLER'
        );
        Test.stopTest();
        System.assertEquals(1, resList.size());
    }
    /**
     * TODO, has to run in a users context
     */
    @isTest
    static void getThreadsCollectionMultiTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(
            accList.get(0).Id,
            false,
            'HOT_BRUKER-FORMIDLER'
        );
        Test.stopTest();
        System.assertEquals(2, resList.size());
    }

    @isTest
    static void getSingleThreadTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        Thread__c thread = new Thread__c();
        thread.CRM_Type__c = 'HOT_BRUKER-TOLK';
        thread.CRM_Related_Object__c = request.Id;
        insert thread;
        Test.startTest();
        List<Thread__c> result = [
            SELECT Id
            FROM Thread__c
            WHERE CRM_Related_Object__c = :request.Id AND CRM_Type__c = 'HOT_BRUKER-TOLK'
        ];
        List<Thread__c> t = HOT_MessageHelper.getSingleThread(request.Id, 'HOT_BRUKER-TOLK');
        Test.stopTest();
        System.assertEquals(t.size(), result.size());
    }
    @isTest
    static void getSingleThreadTest2() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        Thread__c thread = new Thread__c();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread.CRM_Related_Object__c = request.Id;
        HOT_DatabaseOperations.insertRecords(thread);
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getSingleThread(thread.Id, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(t.size(), 0);
    }
    @isTest
    static void getThreads() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;

        Thread__c thread = new Thread__c();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread.CRM_Related_Object__c = request.Id;
        HOT_DatabaseOperations.insertRecords(thread);

        Thread__c thread2 = new Thread__c();
        thread2.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread2.CRM_Related_Object__c = request.Id;
        HOT_DatabaseOperations.insertRecords(thread2);

        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreads(request.Id);
        Test.stopTest();
        System.assertEquals(t.size(), 2);
    }
    @isTest
    static void getThreadFromIdTest() {
        Thread__c thread = new Thread__c();
        insert thread;
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreadFromThreadId(thread.Id);
        Test.stopTest();
        System.assertEquals(t.size(), 1);
    }
    @isTest
    static void createThread() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        account = [SELECT Id FROM Account WHERE FirstName = 'Test' LIMIT 1];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('BRUKER-FORMIDLER', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;

        Test.startTest();
        request = [
            SELECT Id, Subject__c, Account__c, Orderer__c, IsAccountEqualOrderer__c
            FROM HOT_Request__c
            WHERE Subject__c = 'BRUKER-FORMIDLER'
            LIMIT 1
        ];

        Thread__c thread = HOT_MessageHelper.createThread(request.Id, account.Id);

        thread = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :request.Id
            LIMIT 1
        ];

        Test.stopTest();
        System.assertNotEquals(null, thread);
        System.assertEquals(account.Id, thread.CRM_Account__c);
        System.assertEquals(thread.CRM_Type__c, 'HOT_BRUKER-FORMIDLER');
    }
    @isTest
    static void createThreadWorkOrder() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = acc.Id;
        insert workOrder;
        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(workOrder.Id, acc.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrder.Id
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, acc.Id);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-TOLK');
    }
    @isTest
    static void createThreadServiceAppointment() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = acc.Id;
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Subject = 'Hei';
        sa.HOT_Account__c = acc.Id;
        insert sa;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(sa.Id, acc.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrder.Id
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, acc.Id);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-TOLK');
    }
    @isTest
    static void createThreadInterestedResource() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(interestedResource.Id, acc.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id
        ];
        System.assertNotEquals(null, tList);
    }
    @isTest
    static void createThreadDispatcherRequest() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(request.Id, acc.Id, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :request.Id
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, acc.Id);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-FORMIDLER');
    }
    @isTest
    static void createThreadDispatcherWorkOrder() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = acc.Id;
        insert workOrder;
        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(workOrder.Id, acc.Id, 'HOT_BRUKER-TOLK');
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrder.Id
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, acc.Id);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-TOLK');
    }
    @isTest
    static void createThreadDispatcherInterestedResource() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        sa.Status = 'Dispatched';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);

        Test.startTest();
        insert interestedResource;
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(
            interestedResource.Id,
            acc.Id,
            'HOT_TOLK-FORMIDLER'
        );
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id
        ];
        System.assertNotEquals(null, tList);
    }
    @isTest
    static void createThreadInterpreterInterestedResource() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;
        Test.startTest();

        Thread__c thread = HOT_MessageHelper.createThreadInterpreter(interestedResource.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id
        ];
        System.assertNotEquals(null, tList);
    }
    @isTest
    static void getAccountonRequestTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        insert personAccount;
        request.Account__c = personAccount.Id;
        insert request;

        Test.startTest();
        Id accountId = HOT_MessageHelper.getAccountOnRequest(request.Id);
        Test.stopTest();
        System.assertNotEquals(null, accountId);
        System.assertEquals(accountId, personAccount.Id);
    }

    @isTest
    static void getMessagesFromThreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        List<Message__c> msgList = HOT_MessageHelper.getMessagesFromThread(tList.get(0).Id);
        Test.stopTest();
        System.assertEquals(1, msgList.size());
    }
    @isTest
    static void getUserLisenceTest() {
        Test.startTest();
        String lisenceType = HOT_MessageHelper.getUserLisenceType(UserInfo.getUserId());
        Test.stopTest();
        System.assertNotEquals(null, lisenceType);
    }
    @isTest
    static void markasreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.markAsRead(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(true, msgList.get(0).CRM_Read__c);
    }
    @isTest
    static void setLastMessageFromTolk() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.setLastMessageFrom(tList.get(0).Id, 'tolk');
        Test.stopTest();

        List<Thread__c> tList2 = [SELECT Id, HOT_Last_message_from__c FROM Thread__c WHERE Id = :tList.get(0).Id];
        Boolean isEmpty = tList2.get(0).HOT_Last_message_from__c == null;
        System.assertEquals(true, isEmpty);
    }
    @isTest
    static void markAsReadByNavTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.markAsReadByNav(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [
            SELECT CRM_Read_By_Nav__c, CRM_Read_By_Nav_Datetime__c
            FROM Message__c
            WHERE CRM_Thread__c = :tList.get(0).Id
        ];
        System.assertEquals(true, msgList.get(0).CRM_Read_By_Nav__c, 'Could not set CRM_Read_By_Nav__c to true.');
        System.assertNotEquals(
            null,
            msgList.get(0).CRM_Read_By_Nav_Datetime__c,
            'CRM_Read_By_Nav_Datetime__c was not set.'
        );
    }
    @isTest
    static void createMessageTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(msgList.isEmpty(), false);
    }
    @isTest
    static void createMessagesTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.createMessages(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(msgList.isEmpty(), false);
    }
    @isTest
    static void markThreadAsReadTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Thread__c thread = new Thread__c();
        thread.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        thread.CRM_Related_Object__c = request.Id;
        thread.HOT_Thread_read_by__c = '33rnf43r';
        insert thread;

        Thread__c th = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c = :request.Id];

        String contactId = '1343234554';
        HOT_MessageHelper.markThreadAsRead(th.Id, contactId);
        Boolean isReadbyUser;
        Thread__c checkthread = [SELECT Id, HOT_Thread_read_by__c FROM Thread__c WHERE Id = :th.Id];
        if (checkthread.HOT_Thread_read_by__c.contains(contactId)) {
            isReadbyUser = true;
        } else {
            isReadbyUser = false;
        }
        Boolean test = true;
        System.assertEquals(true, isReadbyUser, 'Is not read by user');
    }
    @isTest
    static void getRelatedObjectDetailsTestWO() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        update request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'WO');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(workOrder.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @isTest
    public static void getThreadsFailTest() {
        Id recordId = null;
        test.startTest();
        try {
            List<Thread__c> threads = HOT_MessageHelper.getThreads(recordId);
        } catch (DmlException ex) {
            System.assertEquals('expected text', ex.getMessage());
        }
        test.stopTest();
    }
    @isTest
    public static void createThreadOrdererUserTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;

        test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadOrdererUser(request.Id);
        test.stopTest();
        System.assertEquals('HOT_BRUKER-BESTILLER', thread.CRM_Thread_Type__c);
    }
    @isTest
    static void createThreadWageClaim() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;

        HOT_WageClaim__c wageclaim = HOT_TestDataFactory.createWageClaim(resource);
        wageclaim.ServiceAppointment__c = sa.Id;
        insert wageclaim;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = wageclaim.Id;
        t.CRM_Account__c = acc.Id;
        insert t;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(wageclaim.Id, acc.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :wageclaim.Id
        ];
        System.assertNotEquals(null, tList);
    }
    @isTest
    static void createThreadWageClaimDispatcher() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;

        HOT_WageClaim__c wageclaim = HOT_TestDataFactory.createWageClaim(resource);
        wageclaim.ServiceAppointment__c = sa.Id;
        insert wageclaim;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = wageclaim.Id;
        t.CRM_Account__c = acc.Id;
        insert t;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(wageclaim.Id, acc.Id, 'HOT_TOLK-RESSURSKONTOR');
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :wageclaim.Id
        ];
        System.assertNotEquals(null, tList);
    }
    @isTest
    static void getAccountOnThreadTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Darth Vader';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = request.Id;
        t.CRM_Account__c = acc.Id;
        insert t;
        Test.startTest();
        String result = HOT_MessageHelper.getAccountOnThread(t.Id);
        Test.stopTest();
        System.assertEquals('Darth Vader', result);
    }
    @isTest
    static void getAccountOnThreadWOTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.HOT_Interpreters__c = 'Darth Vader';
        insert workOrder;
        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = workOrder.Id;
        insert t;
        Test.startTest();
        String result = HOT_MessageHelper.getAccountOnThread(t.Id);
        Test.stopTest();
        System.assertEquals('Darth Vader', result);
    }
    @isTest
    static void createThreadInterpreterInterpreters() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Subject = 'Hei';
        insert sa;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadInterpreters(sa.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrder.Id
        ];
        System.assertNotEquals(null, tList);
    }
    @isTest
    static void createThreadDispatcherEmployee() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Subject = 'Hei';
        insert sa;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(sa.Id, acc.Id, 'HOT_TOLK-FORMIDLER');
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :sa.Id
        ];
        System.assertNotEquals(null, tList);
    }
}
