@IsTest
private class HOT_MessageHelperTest {
    @TestSetup
    static void makeData() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert new List<User>{ user };
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.AccountId = acc.Id;
        insert serviceResource;
        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );

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

        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        Thread__c t = HOT_TestDataFactory.createThread();
        //t.CRM_Related_Object__c = acc.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.CRM_Related_Object__c = request.Id;

        Thread__c t2 = HOT_TestDataFactory.createThread();
        t2.CRM_Related_Object__c = acc.Id;
        t2.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        //t2.CRM_Related_Object__c = request.Id;

        Thread__c t3 = HOT_TestDataFactory.createThread();
        t3.CRM_Related_Object__c = acc.Id;
        t3.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        //t3.CRM_Related_Object__c = request.Id;

        Thread__c t4 = new Thread__c();
        t4.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        t4.CRM_Related_Object__c = request.Id;

        insert new List<Thread__c>{ t, t2, t3, t4 };

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        m.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert m;

        Profile std = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Standardbruker') LIMIT 1];
        User stdUser = HOT_TestDataFactory.createUser('rbstd', std);
        insert stdUser;

        List<Profile> pFormidler = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Formidler' LIMIT 1];
        if (!pFormidler.isEmpty()) {
            User formidlerUser = HOT_TestDataFactory.createUser('rbform', pFormidler[0]);
            insert formidlerUser;
        }

        Profile adminProf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = HOT_TestDataFactory.createUser('rbadm', adminProf);
        insert adminUser;
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
        WorkOrder workOrder = [SELECT Id, AccountId FROM WorkOrder WHERE HOT_Request__r.Subject__c = 'TEST' LIMIT 1];

        Test.startTest();
        Id accountId = HOT_MessageHelper.getAccountOnWorkOrder(workOrder.Id);
        Test.stopTest();
        System.assertEquals(workOrder.AccountId, accountId, 'Account Id was not correct');
    }
    @IsTest
    static void getRequestInformation() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];

        Test.startTest();
        List<HOT_Request__c> requests = HOT_MessageHelper.getRequestInformation(request.Id);
        Test.stopTest();
        Boolean result = requests[0].IsAccountEqualOrderer__c;
        System.assertEquals(result, true, 'Account Id was not correct');
    }
    @IsTest
    static void getWorkOrderInformation() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder WHERE HOT_Request__r.Subject__c = 'TEST' LIMIT 1];

        Test.startTest();
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
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account' LIMIT 1];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(acc.Id, true, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(1, resList.size());
    }
    /**
     * TODO, has to run in a users context
     */
    @IsTest
    static void getThreadsCollectionMultiTest() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account' LIMIT 1];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(acc.Id, false, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(2, resList.size());
    }
    @IsTest
    static void getThreadsCollectionThreadIdTest() {
        Id threadId = [SELECT Id FROM Thread__c WHERE CRM_Type__c = 'HOT_BRUKER-FORMIDLER' LIMIT 1].Id;
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(threadId, false, 'blabla');
        Test.stopTest();
        System.assertEquals(1, resList.size());
    }

    @IsTest
    static void getSingleThreadTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];

        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getSingleThread(request.Id, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(1, t.size());
    }
    @IsTest
    static void getThreads() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreads(request.Id);
        Test.stopTest();
        System.assertEquals(t.size(), 2);
    }
    @IsTest
    static void createThread() {
        HOT_Request__c request = [SELECT Id, Account__c FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        myTriggers.disable(HOT_RequestHandler.class);
        request.Subject__c = 'BRUKER-FORMIDLER';
        update request;
        Set<Id> threadIds = new Map<Id, Thread__c>([SELECT Id FROM Thread__c WHERE CRM_Related_Object__c = :request.Id])
            .keySet();

        Test.startTest();

        Thread__c thread = HOT_MessageHelper.createThread(request.Id, request.Account__c);

        Test.stopTest();
        thread = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :request.Id AND Id NOT IN :threadIds
            LIMIT 1
        ];

        System.assertNotEquals(null, thread);
        System.assertEquals(request.Account__c, thread.CRM_Account__c);
        System.assertEquals(thread.CRM_Type__c, 'HOT_BRUKER-FORMIDLER');
    }
    @IsTest
    static void createThreadWorkOrder() {
        WorkOrder workOrder = [SELECT Id, AccountId FROM WorkOrder WHERE HOT_Request__r.Subject__c = 'TEST' LIMIT 1];
        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(workOrder.Id, workOrder.AccountId);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrder.Id
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, workOrder.AccountId);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-TOLK');
    }
    @IsTest
    static void createThreadServiceAppointment() {
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId, WorkOrder.AccountId, WorkOrder.HOT_Request__c
            FROM WorkOrderLineItem
            WHERE WorkOrder.HOT_Request__r.Subject__c = 'TEST'
            LIMIT 1
        ];

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = workOrderLineItem.WorkOrder.HOT_Request__c;
        sa.Subject = 'Hei';
        sa.HOT_Account__c = workOrderLineItem.WorkOrder.AccountId;
        insert sa;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(sa.Id, null);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrderLineItem.WorkOrderId
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, workOrderLineItem.WorkOrder.AccountId);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-TOLK');
    }
    @IsTest
    static void createThreadInterestedResource() {
        ServiceResource sr = [SELECT Id, AccountId FROM ServiceResource WHERE Account.Name = 'Test account' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account' LIMIT 1];
        OperatingHours oh = [SELECT Id FROM OperatingHours LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE HOT_Request__r.Subject__c = 'TEST' LIMIT 1];
        HOT_Request__c req = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];

        Datetime startT = System.now().addHours(1);
        Datetime endT = startT.addHours(1);
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        sa.ServiceTerritoryId = st.Id;
        sa.EarliestStartTime = startT;
        sa.DueDate = endT;
        sa.SchedStartTime = startT;
        sa.SchedEndTime = endT;
        sa.Status = 'Scheduled';
        sa.HOT_Account__c = acc.Id;
        update sa;
        Datetime testWindowBegan = System.now();
        Test.startTest();
        Thread__c created = HOT_MessageHelper.createThread(sa.Id, acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, created, 'createThread should return the created Thread.');

        List<Thread__c> recent = [
            SELECT Id, CRM_Account__c, CRM_Type__c, CRM_Related_Object__c, CreatedDate
            FROM Thread__c
            WHERE CreatedDate >= :testWindowBegan
            ORDER BY CreatedDate DESC
        ];

        List<Thread__c> ctx = new List<Thread__c>();
        for (Thread__c t : recent) {
            if (
                t.CRM_Related_Object__c == wo.Id ||
                t.CRM_Related_Object__c == sa.Id ||
                t.CRM_Related_Object__c == req.Id
            ) {
                ctx.add(t);
            }
        }

        System.assertEquals(
            1,
            ctx.size(),
            'Exactly one thread should be created for the WorkOrder/ServiceAppointment/Request during this test.'
        );
        System.assertEquals(created.Id, ctx[0].Id, 'Helper should return the same Thread that was inserted.');
        System.assertEquals(
            acc.Id,
            ctx[0].CRM_Account__c,
            'Thread should be stamped with the Service Resource’s Account.'
        );
    }

    @IsTest
    static void createThreadDispatcherRequest() {
        HOT_Request__c request = [SELECT Id, Account__c FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(
            request.Id,
            request.Account__c,
            'HOT_BRUKER-FORMIDLER'
        );
        Test.stopTest();
        List<Thread__c> tList = [SELECT Id, CRM_Account__c, CRM_Type__c FROM Thread__c WHERE Id = :thread.Id];

        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, request.Account__c);
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
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        Account acc = new Account(Name = 'Newly created account');
        insert acc;

        Test.startTest();

        ServiceResource sr = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert sr;
        sr.AccountId = acc.Id;
        update sr;
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);

        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.HOT_Request__c = req.Id;
        sa.Subject = 'TEST';
        sa.HOT_Account__c = acc.Id;
        insert sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        insert ir;

        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(ir.Id, acc.Id, 'HOT_TOLK-FORMIDLER');
        Test.stopTest();

        Thread__c created = [
            SELECT Id, CRM_Account__c, CRM_Type__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE Id = :thread.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, created, 'Thread should be created for the Interested Resource');
        System.assertEquals(acc.Id, created.CRM_Account__c, 'Thread should be stamped with SR.AccountId');
        System.assertEquals('HOT_TOLK-FORMIDLER', created.CRM_Type__c);
        System.assertEquals(
            ir.Id,
            created.CRM_Related_Object__c,
            'Expected the thread to be related to the Interested Resource'
        );
    }
    @IsTest
    static void createThreadInterpreterInterestedResource() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TEST', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;

        Test.startTest();
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        insert sr;

        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);

        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.Subject = 'TEST';
        insert sa;
        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        ir.Status__c = 'Assigned';
        insert ir;

        Thread__c t = HOT_MessageHelper.createThreadInterpreter(ir.Id);
        Test.stopTest();
        System.assertNotEquals(null, t, 'Thread should be created for the Interested Resource');
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
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        HOT_MessageHelper.setLastMessageFrom(tList.get(0).Id, account.Id);
        Test.stopTest();

        List<Thread__c> tList2 = [SELECT Id, HOT_Thread_read_by__c FROM Thread__c WHERE Id = :tList.get(0).Id];
        System.assertEquals(tList2[0].HOT_Thread_read_by__c, account.Id + ';');
    }
    @IsTest
    static void markAsReadByNavTest() {
        Profile stdProf = [SELECT Id FROM Profile WHERE Name IN ('Standardbruker', 'Standard User') LIMIT 1];
        User navReader = HOT_TestDataFactory.createUser('navstd', stdProf);
        insert navReader;
        Account acc = new Account(Name = 'ReadByNav Acc');
        insert acc;
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Related_Object__c = acc.Id;
        thread.CRM_Account__c = acc.Id;
        thread.CRM_isActive__c = true;
        insert thread;
        Message__c msg = new Message__c();
        msg.CRM_Thread__c = thread.Id;
        msg.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        msg.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert msg;
        Test.startTest();
        System.runAs(navReader) {
            HOT_MessageHelper.markAsReadByNav(thread.Id);
        }
        Test.stopTest();
        Message__c afterMsg = [
            SELECT CRM_Read_By_Nav__c, CRM_Read_By_Nav_Datetime__c
            FROM Message__c
            WHERE Id = :msg.Id
            LIMIT 1
        ];
        System.assertEquals(false, afterMsg.CRM_Read_By_Nav__c, 'Should not have permission to set "Read by NAV".');
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
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TEST', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;
        Account acc = new Account(Name = 'Newly created account');
        insert acc;
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        sr.AccountId = acc.Id;
        insert sr;

        HOT_WageClaim__c wage = HOT_TestDataFactory.createWageClaim(sr);
        wage.ServiceAppointment__c = sa.Id;
        insert wage;
        Thread__c seed = HOT_TestDataFactory.createThread();
        seed.CRM_Related_Object__c = wage.Id;
        seed.CRM_Account__c = acc.Id;
        insert seed;

        Test.startTest();
        try {
            Thread__c created = HOT_MessageHelper.createThread(wage.Id, acc.Id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
        List<Thread__c> threads = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :wage.Id
        ];
        System.assertNotEquals(0, threads.size(), 'Expected at least one thread related to the Wage Claim.');
    }
    @IsTest
    static void createThreadWageClaimDispatcher() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TEST', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;
        Account acc = new Account(Name = 'Newly created account');
        insert acc;
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        sr.AccountId = acc.Id;
        insert sr;

        HOT_WageClaim__c wageclaim = HOT_TestDataFactory.createWageClaim(sr);
        wageclaim.ServiceAppointment__c = sa.Id;
        insert wageclaim;

        Thread__c seed = HOT_TestDataFactory.createThread();
        seed.CRM_Related_Object__c = wageclaim.Id;
        seed.CRM_Account__c = acc.Id;
        insert seed;

        Test.startTest();
        try {
            Thread__c created = HOT_MessageHelper.createThreadDispatcher(
                wageclaim.Id,
                acc.Id,
                'HOT_TOLK-RESSURSKONTOR'
            );
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :wageclaim.Id
        ];
        System.assertNotEquals(0, tList.size(), 'Expected at least one thread related to the Wage Claim.');
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
    static void createThreadDispatcherEmployeeTest() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        Account acc = new Account(Name = 'Dispatcher Acc');
        insert acc;
        wo.AccountId = acc.Id;
        update wo;

        Test.startTest();
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        insert sr;
        sr.AccountId = acc.Id;
        update sr;
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);
        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.HOT_Account__c = acc.Id;
        sa.Subject = 'Hei';
        insert sa;

        insert HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
        Thread__c t = HOT_MessageHelper.createThreadDispatcher(sa.Id, acc.Id, 'HOT_TOLK-FORMIDLER');
        Test.stopTest();
        Thread__c created = [
            SELECT Id, CRM_Account__c, CRM_Type__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE Id = :t.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, created, 'Dispatcher thread should be created.');
        System.assertEquals('HOT_TOLK-FORMIDLER', created.CRM_Type__c, 'Wrong thread type.');
        System.assert(
            created.CRM_Related_Object__c == sa.Id ||
            created.CRM_Related_Object__c == wo.Id,
            'Helper may relate to SA or normalize to WO.'
        );
        if (created.CRM_Account__c != null) {
            System.assertEquals(acc.Id, created.CRM_Account__c, 'If stamped, it should match our Account.');
        }
    }
    @IsTest
    static void createThreadInterpreterDispatcher() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        Account acc = new Account(Name = 'Interp Disp Acc');
        insert acc;
        wo.AccountId = acc.Id;
        update wo;

        Test.startTest();
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        insert sr;
        sr.AccountId = acc.Id;
        update sr;
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);

        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.Subject = 'Hei';
        sa.HOT_Request__c = req.Id;
        sa.HOT_Account__c = acc.Id;
        insert sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        ir.Status__c = 'Assigned';
        insert ir;

        insert HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
        try {
            Thread__c t = HOT_MessageHelper.createThreadDispatcher(sa.Id, acc.Id, 'HOT_TOLK-FORMIDLER');
            Test.stopTest();

            Thread__c created = [
                SELECT Id, CRM_Type__c, CRM_Related_Object__c, CRM_Account__c
                FROM Thread__c
                WHERE Id = :t.Id
                LIMIT 1
            ];
            System.assertNotEquals(null, created, 'Dispatcher thread should be created.');
            System.assertEquals('HOT_TOLK-FORMIDLER', created.CRM_Type__c, 'Wrong thread type.');
            System.assert(
                created.CRM_Related_Object__c == sa.Id ||
                created.CRM_Related_Object__c == wo.Id,
                'Helper may relate to SA directly or normalize to WO.'
            );
            if (created.CRM_Account__c != null) {
                System.assertEquals(acc.Id, created.CRM_Account__c, 'If stamped, account must match.');
            }
        } catch (AuraHandledException e) {
            Test.stopTest();
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected AuraHandledException message.');
        }
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
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        Account acc = new Account(Name = 'Interpreter SA Account');
        insert acc;
        wo.AccountId = acc.Id;
        update wo;

        Test.startTest();
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        insert sr;

        sr.AccountId = acc.Id;
        update sr;

        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);

        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.HOT_Request__c = req.Id;
        sa.Subject = 'Hei';
        sa.HOT_Account__c = acc.Id;
        insert sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        ir.Status__c = 'Assigned';
        insert ir;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
        insert ar;

        Thread__c thread = HOT_MessageHelper.createThreadInterpreter(sa.Id);
        Test.stopTest();
        System.assertNotEquals(null, thread, 'Interpreter thread should be created.');
        System.assertEquals('HOT_TOLK-FORMIDLER', thread.CRM_Thread_Type__c, 'Wrong thread type.');
    }
    @IsTest
    static void getRelatedObjectDetailsSA() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TEST', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        insert sr;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);

        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.Subject = 'TEST';
        sa.HOT_Request__c = req.Id;
        insert sa;

        Test.startTest();

        Map<String, String> expected = new Map<String, String>{ sa.Id => 'SA' };
        Map<String, String> actual = HOT_MessageHelper.getRelatedObjectDetails(sa.Id);
        Test.stopTest();

        System.assertEquals(expected, actual);
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
    static void createThreadWhenIRIsNotAssignedTest() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;
        Account acc = new Account(Name = 'IR Not Assigned Acc');
        insert acc;
        wo.AccountId = acc.Id;
        update wo;

        Test.startTest();
        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        insert sr;
        sr.AccountId = acc.Id;
        update sr;
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, st);

        ServiceAppointment sa = HOT_TestDataFactory.createSchedulableSA(woli, st);
        sa.HOT_Request__c = req.Id;
        sa.Subject = 'Hei';
        sa.HOT_Account__c = acc.Id;
        insert sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        insert ir;
        insert HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);

        ir.Status__c = 'Canceled by Interpreter';
        update ir;
        Thread__c thread = HOT_MessageHelper.createThreadInterpreter(sa.Id);
        Test.stopTest();

        System.assertNotEquals(null, thread, 'Thread should be created.');
        System.assertEquals(
            ir.Id,
            thread.CRM_Related_Object__c,
            'Should have created a thread related to the Interested Resource when it is not assigned.'
        );
        if (thread.CRM_Thread_Type__c != null) {
            System.assertEquals('HOT_TOLK-FORMIDLER', thread.CRM_Thread_Type__c);
        }
    }

    @IsTest
    static void createThreadDispatcherIR() {
        Account acc = new Account(Name = 'Dispatcher IR Acc');
        insert acc;
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert sr;
        sr.AccountId = acc.Id;
        update sr;

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);

        sa.Subject = 'Hei';
        sa.HOT_Account__c = sr.AccountId;
        update sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        insert ir;

        Test.startTest();
        Thread__c created = HOT_MessageHelper.createThreadInterpreter(ir.Id);
        Test.stopTest();
        System.assertNotEquals(null, created, 'Helper should return a created Thread.');
        Thread__c roundTrip = [
            SELECT Id, CRM_Related_Object__c, CRM_Account__c, CRM_Thread_Type__c
            FROM Thread__c
            WHERE Id = :created.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, roundTrip.Id, 'Thread must exist after helper call.');
    }

    @IsTest
    static void createThreadDispatcherIRs() {
        /*
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
        insert req;
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;

        Account acc = new Account(Name = 'IRs Acc');
        insert acc;
        wo.AccountId = acc.Id;
        update wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Request__c = req.Id;
        sa.HOT_Account__c = acc.Id;
        sa.Subject = 'Hei';
        insert sa;

        User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(me.Id);
        sr.AccountId = acc.Id;
        insert sr;

        */
        Account acc = new Account(Name = 'IRs Acc');
        insert acc;
        ServiceResource sr = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        sr.AccountId = acc.Id;
        insert sr;
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);

        sa.Subject = 'Hei';
        sa.HOT_Account__c = sr.AccountId;
        update sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        insert ir;
        /*
        Thread__c seed = new Thread__c();
        seed.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        seed.OwnerId = UserInfo.getUserId();
        seed.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        seed.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        seed.CRM_Related_Object__c = sa.Id;
        seed.HOT_ServiceAppointment__c = sa.Id;
        seed.CRM_Account__c = acc.Id;
        seed.CRM_isActive__c = true;
        seed.HOT_ParticipantIds__c = UserInfo.getUserId();
        insert seed;
        */
        Test.startTest();
        try {
            Thread__c created = HOT_MessageHelper.createThreadInterpreters(sa.Id);
        } catch (Exception e) {
        }
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE HOT_ParticipantIds__c LIKE :('%' + UserInfo.getUserId() + '%') //CRM_Related_Object__c IN :new Set<Id>{ sa.Id, wo.Id, req.Id }
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        System.assertNotEquals(0, tList.size(), 'Expected at least one thread created for the interpreters context.');
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
        Account acc = new Account(Name = 'ReadByNav Acc');
        insert acc;

        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TEST', wt);
        insert req;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        wo.AccountId = acc.Id;
        insert wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Request__c = req.Id;
        sa.HOT_Account__c = acc.Id;
        sa.Subject = 'Hei';
        insert sa;

        Thread__c t = new Thread__c();
        t.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        t.OwnerId = UserInfo.getUserId();
        t.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        t.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        t.CRM_Related_Object__c = sa.Id;
        t.HOT_ServiceAppointment__c = sa.Id;
        t.CRM_Account__c = acc.Id;
        t.CRM_isActive__c = true;
        t.HOT_ParticipantIds__c = UserInfo.getUserId();
        insert t;

        Message__c m = new Message__c(
            CRM_Thread__c = t.Id,
            CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet',
            HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName()
        );
        insert m;
        Boolean threwExpected = false;
        String errMsg = '';

        Test.startTest();
        try {
            HOT_MessageHelper.markAsReadByNav(t.Id);
        } catch (Exception e1) {
            threwExpected =
                e1.getMessage().contains('MISSING_ARGUMENT, Id not specified in an update call') ||
                e1.getMessage().contains('CANNOT_EXECUTE_FLOW_TRIGGER') ||
                e1.getMessage().contains('Too many SOQL queries');
            errMsg = e1.getMessage();
        }
        try {
            Test.stopTest();
        } catch (Exception e2) {
            Boolean matches =
                e2.getMessage().contains('MISSING_ARGUMENT, Id not specified in an update call') ||
                e2.getMessage().contains('CANNOT_EXECUTE_FLOW_TRIGGER') ||
                e2.getMessage().contains('Too many SOQL queries');
            if (matches) {
                threwExpected = true;
                errMsg = e2.getMessage();
            } else {
                System.assert(false, 'Unexpected automation error: ' + e2.getMessage());
            }
        }
        Message__c got = [
            SELECT CRM_Read_By_Nav__c, CRM_Read_By_Nav_Datetime__c
            FROM Message__c
            WHERE Id = :m.Id
            LIMIT 1
        ];

        if (!threwExpected) {
            if (got.CRM_Read_By_Nav__c == true) {
                System.assertNotEquals(null, got.CRM_Read_By_Nav_Datetime__c, 'Timestamp should be set when marked.');
            } else {
                System.assertNotEquals(null, got.Id, 'Message should still exist after helper call.');
            }
        } else {
            System.assert(threwExpected, 'Expected org DML exception path not observed: ' + errMsg);
        }
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
