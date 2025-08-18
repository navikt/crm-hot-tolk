@IsTest
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
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;
    }
    @IsTest
    static void getObjectTypeFromidTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        String objectType = HOT_MessageHelper.getRecordObjectType(acclist.get(0).Id);
        Test.stopTest();
        System.assertEquals('Account', objectType, 'Object type is not recoginzed as expected');
    }
    @IsTest
    static void getUserContactId() {
        Test.startTest();
        String contactId = HOT_MessageHelper.getUserContactId();
        Test.stopTest();
        System.assertEquals(null, contactId, 'User Contact Id was not returned correctly');
    }
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
    static void getThreadsCollectionThread() {
        Thread__c t = [SELECT Id FROM Thread__c WHERE CRM_Type__c = 'HOT_BRUKER-FORMIDLER' LIMIT 1];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(t.Id, true, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(1, resList.size());
    }
    @IsTest
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
    @IsTest
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

    @IsTest
    static void getSingleThreadTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        account = [SELECT Id FROM Account WHERE FirstName = 'Test' LIMIT 1];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('BRUKER-FORMIDLER', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
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
    @IsTest
    static void getSingleThreadTest2() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread.CRM_Related_Object__c = request.Id;
        HOT_DatabaseOperations.insertRecords(thread);
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getSingleThread(thread.Id, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(t.size(), 0);
    }
    @IsTest
    static void getThreads() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread.CRM_Related_Object__c = request.Id;
        HOT_DatabaseOperations.insertRecords(thread);

        Thread__c thread2 = new Thread__c();
        thread2.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread2.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread2.CRM_Related_Object__c = request.Id;
        HOT_DatabaseOperations.insertRecords(thread2);

        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreads(request.Id);
        Test.stopTest();
        System.assertEquals(t.size(), 2);
    }
    @IsTest
    static void getThreadFromIdTest() {
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        insert thread;
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreadFromThreadId(thread.Id);
        Test.stopTest();
        System.assertEquals(t.size(), 1);
    }
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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

    @IsTest
    static void getMessagesFromThreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        List<Message__c> msgList = HOT_MessageHelper.getMessagesFromThread(tList.get(0).Id);
        Test.stopTest();
        System.assertEquals(null, msgList, 'Should not have got any messages because no access');
    }
    @IsTest
    static void getUserLisenceTest() {
        Test.startTest();
        String lisenceType = HOT_MessageHelper.getUserLisenceType(UserInfo.getUserId());
        Test.stopTest();
        System.assertNotEquals(null, lisenceType);
    }
    @IsTest
    static void markasreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.markAsRead(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(false, msgList.get(0).CRM_Read__c, 'Should not be marked as red because no access');
    }
    @IsTest
    static void setLastMessageFromTolk() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.setLastMessageFrom(tList.get(0).Id, 'ansatt/formidler');
        Test.stopTest();

        List<Thread__c> tList2 = [SELECT Id, HOT_Thread_read_by__c FROM Thread__c WHERE Id = :tList.get(0).Id];
        Boolean isNotEmpty = tList2.get(0).HOT_Thread_read_by__c != null;
        System.assertEquals(true, isNotEmpty);
    }
    @IsTest
    static void setLastMessageFromUser() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        Contact contact = new Contact(
            FirstName = 'Darth',
            LastName = 'Vader',
            Phone = '95410816',
            AccountId = currentUser.AccountId
        );
        insert contact;
        HOT_MessageHelper.setLastMessageFrom(tList.get(0).Id, contact.Id);
        Test.stopTest();

        List<Thread__c> tList2 = [SELECT Id, HOT_Thread_read_by__c FROM Thread__c WHERE Id = :tList.get(0).Id];
        System.assertEquals(tList2[0].HOT_Thread_read_by__c, contact.Id + ';');
    }
    @IsTest
    static void markAsReadByNavTest() {
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
        sa.Status = 'Dispatched';
        sa.Subject = 'Hei';
        insert sa;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId = acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;

        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(sa.Id, acc.Id, 'HOT_TOLK-FORMIDLER');
        Message__c m = new Message__c();
        m.CRM_Thread__c = thread.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Profile profile2 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
            emailencodingkey = 'UTF-8',
            lastname = 'Testing',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = profile2.Id,
            country = 'Norway',
            IsActive = true,
            timezonesidkey = 'Europe/Paris',
            username = 'HOT_testaccount@nav.hot.noo'
        );

        HOT_MessageHelper.markAsReadByNav(thread.Id);

        Test.stopTest();
        List<Message__c> msgList = [
            SELECT CRM_Read_By_Nav__c, CRM_Read_By_Nav_Datetime__c
            FROM Message__c
            WHERE CRM_Thread__c = :thread.Id
        ];
        System.assertEquals(false, msgList.get(0).CRM_Read_By_Nav__c, 'Should not have permission to set read by nav');
    }
    @IsTest
    static void createMessageTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(msgList.isEmpty(), false);
    }
    @IsTest
    static void createMessagesTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.createMessages(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(msgList.isEmpty(), false);
    }
    @IsTest
    static void createMessageTestNotActive() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        tList[0].CRM_isActive__c = false;
        update tList;
        Test.startTest();
        Boolean result = HOT_MessageHelper.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        System.assertEquals(false, result);
    }
    @IsTest
    static void markThreadAsReadTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
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
        System.assertEquals(false, isReadbyUser, 'Does not have access to be marked as red.');
    }
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
        System.assertEquals(null, result);
    }
    @IsTest
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
        System.assertEquals('Darth Vader', result, 'Did not get correct name');
    }
    @IsTest
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
    @IsTest
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
    @IsTest
    static void createThreadInterpreterDispatcher() {
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
        sa.Status = 'Dispatched';
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
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        Test.startTest();
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;

        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(sa.Id, acc.Id, 'HOT_TOLK-FORMIDLER');
        Test.stopTest();
        System.assertEquals('HOT_TOLK-FORMIDLER', thread.CRM_Thread_Type__c);
    }
    @IsTest
    public static void createThreadOrdererDispatcher() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.Orderer__c = currentUser.AccountId;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        System.runAs(currentUser) {
            Thread__c t = HOT_MessageHelper.createThread(request.Id, account.Id);
            System.assertEquals('HOT_BESTILLER-FORMIDLER', t.CRM_Thread_Type__c, 'Did not create the thread');
        }
    }
    @IsTest
    static void createThreadInterpreterDispatcherSA() {
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
        sa.Status = 'Dispatched';
        sa.Subject = 'Hei';
        insert sa;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        Test.startTest();
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;

        Thread__c thread = HOT_MessageHelper.createThreadInterpreter(sa.Id);
        Test.stopTest();
        System.assertEquals('HOT_TOLK-FORMIDLER', thread.CRM_Thread_Type__c);
    }
    @IsTest
    static void getRelatedObjectDetailsSA() {
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

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        Test.startTest();
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;
        sa.Status = 'Dispatched';
        update sa;

        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(sa.Id, 'SA');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(workOrder.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsSAIrNotFound() {
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

        Test.startTest();
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;

        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'WO');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(workOrder.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsNoSA() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'WO');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(workOrder.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsOrdererRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = currentUser.AccountId;
        request.Account__c = account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'Andre-WO');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(request.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsOrdererRequestSeries() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = currentUser.AccountId;
        request.Account__c = account.Id;
        request.NumberOfWorkOrders__c = 2;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'Andre-R');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(request.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsUserRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = currentUser.AccountId;
        request.Account__c = currentUser.AccountId;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'WO');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(request.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsUserRequestSeries() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = currentUser.AccountId;
        request.Account__c = currentUser.AccountId;
        request.NumberOfWorkOrders__c = 2;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(workOrder.Id, 'R');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(request.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsSA2() {
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

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(sa.Id, 'SA');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(sa.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsIR() {
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

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(interestedResource.Id);
        Test.stopTest();
        System.assertNotEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getRelatedObjectDetailsWC() {
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

        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;

        HOT_WageClaim__c wageclaim = HOT_TestDataFactory.createWageClaim(resource);
        wageclaim.ServiceAppointment__c = sa.Id;
        insert wageclaim;

        Test.startTest();
        Map<String, String> navigationhelp2 = new Map<String, String>();
        navigationhelp2.put(wageclaim.Id, 'WC');
        Map<String, String> navigationhelp = new Map<String, String>();
        navigationhelp = HOT_MessageHelper.getRelatedObjectDetails(wageclaim.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    @IsTest
    static void getUserProfileAndNameTest() {
        Test.startTest();
        String result = HOT_MessageHelper.getUserProfileAndName();
        Test.stopTest();
        System.assertNotEquals('', result, 'Did not get Profile and Name');
    }
    @IsTest
    static void createThreadWhenIRIsAssignedTest() {
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
        sa.Status = 'Dispatched';
        sa.Subject = 'Hei';
        insert sa;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        Test.startTest();
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;
        System.runAs(currentUser) {
            Thread__c thread = HOT_MessageHelper.createThreadInterpreter(sa.Id);

            System.assertEquals(
                sa.Id,
                thread.CRM_Related_Object__c,
                'Should have made a thread with relatedobject serviceAppointment'
            );
        }
        Test.stopTest();
    }
    @IsTest
    static void createThreadWhenIRIsNotAssignedTest() {
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
        sa.Status = 'Dispatched';
        sa.Subject = 'Hei';
        insert sa;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = currentUser.AccountId;
        insert resource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;
        Test.startTest();
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;
        interestedResource.Status__c = 'Canceled by Interpreter';
        update interestedResource;
        System.runAs(currentUser) {
            Thread__c thread = HOT_MessageHelper.createThreadInterpreter(sa.Id);

            System.assertEquals(
                interestedResource.Id,
                thread.CRM_Related_Object__c,
                'Should have made a thread with relatedobject interestedresource'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void createThreadDispatcherIR() {
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

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadInterpreter(interestedResource.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :sa.Id
        ];
        System.assertNotEquals(null, tList);
    }

    @IsTest
    static void createThreadDispatcherIRs() {
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

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadInterpreters(sa.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :sa.Id
        ];
        System.assertNotEquals(null, tList);
    }

    @IsTest
    static void getMessagesFromThreadTestAcc() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Test.startTest();
        List<Message__c> msgList = HOT_MessageHelper.getMessagesFromThread(t.id);
        Test.stopTest();
        assert.isNotNull(msgList, 'Should have got  messages because it should have access');
    }

    @IsTest
    static void getUserLisenceTypeErr() {
        id a = [SELECT Id FROM Account LIMIT 1].id;

        Test.startTest();
        try {
            string s = HOT_MessageHelper.getUserLisenceType(a);
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void markasreadTestAcc() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Test.startTest();
        HOT_MessageHelper.markAsRead(t.Id);
        Test.stopTest();
        Message__c msg = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :t.Id LIMIT 1];
        System.assertEquals(true, msg.CRM_Read__c, 'Should be marked as read because user has access');
    }

    @IsTest
    static void markThreadAsReadTestAcc() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        t.HOT_Thread_read_by__c = '007';
        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        String contactId = '123456';

        Test.startTest();
        HOT_MessageHelper.markThreadAsRead(t.Id, contactId);
        Test.stopTest();
        Thread__c th = [SELECT HOT_Thread_read_by__c FROM Thread__c WHERE id = :t.Id LIMIT 1];
        System.assertEquals('007123456;', th.HOT_Thread_read_by__c, 'Should be HOT Thread Read By + contactid + ;');
    }

    @IsTest
    static void markThreadAsReadEmployeeTestAcc() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        t.HOT_Thread_read_by__c = '007';
        t.HOT_ParticipantIds__c = currentUser.id;
        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Test.startTest();
        HOT_MessageHelper.markThreadAsReadEmployee(t.Id);
        Test.stopTest();
        Thread__c th = [SELECT HOT_Thread_read_by__c FROM Thread__c WHERE id = :t.Id LIMIT 1];
        System.assertEquals(
            '007' +
            currentUser.id +
            ';',
            th.HOT_Thread_read_by__c,
            'Should be HOT Thread Read By + user id + ;'
        );
    }

    @IsTest
    static void markAsReadByNavTestAcc() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = acc.Id;
        insert workOrder;

        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Subject = 'Hei';
        sa.HOT_Account__c = acc.Id;
        insert sa;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        t.HOT_Thread_read_by__c = '007';
        t.HOT_ParticipantIds__c = '123456';
        t.HOT_ServiceAppointment__c = sa.id;
        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Test.startTest();
        HOT_MessageHelper.markAsReadByNav(t.Id);
        Test.stopTest();
        Message__c msg = [SELECT CRM_Read_By_Nav__c FROM Message__c WHERE CRM_Thread__c = :t.Id LIMIT 1];
        System.assertEquals(true, msg.CRM_Read_By_Nav__c, 'Should be true');
    }

    @IsTest
    static void markAsReadByNavTestAccSA() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = acc.Id;
        insert workOrder;

        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Subject = 'Hei';
        sa.HOT_Account__c = acc.Id;
        insert sa;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        t.HOT_Thread_read_by__c = '007';
        t.HOT_ParticipantIds__c = '123456';
        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Test.startTest();
        HOT_MessageHelper.markAsReadByNav(t.Id);
        Test.stopTest();
        Message__c msg = [SELECT CRM_Read_By_Nav__c FROM Message__c WHERE CRM_Thread__c = :t.Id LIMIT 1];
        System.assertEquals(true, msg.CRM_Read_By_Nav__c, 'Should be true');
    }

    @IsTest
    static void getUserNameRoleTolk() {
        User u = [SELECT Id, FirstName FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String r = HOT_MessageHelper.getUserNameRole();
        System.assertEquals(
            u.FirstName + ', Administrator',
            r,
            'Should return the first name of running user + profile name'
        );

        Test.stopTest();
    }

    @IsTest
    static void createMessageAcc() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;

        contact c = [SELECT id FROM Contact LIMIT 1];

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.AccountId = acc.Id;
        insert resource;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = resource.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_ServiceResource__c = resource.Id;
        t.HOT_Thread_read_by__c = '007';
        t.HOT_ParticipantIds__c = currentUser.id;
        t.CRM_isActive__c = true;
        insert t;

        Thread__c t2 = HOT_TestDataFactory.createThread();
        t2.CRM_Related_Object__c = resource.Id;
        t2.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t2.HOT_ServiceResource__c = resource.Id;
        t2.HOT_Thread_read_by__c = '007';
        t2.HOT_ParticipantIds__c = currentUser.id;
        t2.CRM_isActive__c = false;
        insert t2;

        Thread__c t3 = HOT_TestDataFactory.createThread();
        insert t3;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Test.startTest();
        Boolean r = HOT_MessageHelper.createMessage(t.Id, 'Test', c.id);
        Boolean r2 = HOT_MessageHelper.createMessage(t2.Id, 'Test', c.id);
        Boolean r3 = HOT_MessageHelper.createMessage(t3.Id, 'Test', c.id);
        Test.stopTest();
        System.assertEquals(true, r, 'Should be True because crm_isactive__c');
        System.assertEquals(false, r2, 'Should be False because crm_isactive__c');
        System.assertEquals(false, r3, 'Should be False because no access');
    }
}
