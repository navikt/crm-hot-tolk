@isTest
public with sharing class HOT_MessageHelperTest {
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
        request.Account__c=account.Id;
        request.Orderer__c=account.Id;
        insert request;


        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = acc.Id;
        t.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.CRM_Related_Object__c=request.Id;

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
    static void getAccountOnWorkOrder(){
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
        Id accountId=HOT_MessageHelper.getAccountOnWorkOrder(workOrder.Id);
        Test.stopTest();
        System.assertEquals(workOrder.AccountId, accountId, 'Account Id was not correct');
    }
      @isTest
    static void getRequestInformation(){
         

        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c=account.Id;
        request.Orderer__c=account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;
        
        List<HOT_Request__c> requests=HOT_MessageHelper.getRequestInformation(request.Id);
        Boolean result=requests[0].IsAccountEqualOrderer__c;
        Test.stopTest();
        System.assertEquals(result, true, 'Account Id was not correct');
    }
    @isTest
    static void getThreadsCollectionSingleTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(accList.get(0).Id, true, 'HOT_BRUKER-FORMIDLER');
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
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(accList.get(0).Id, false, 'HOT_BRUKER-FORMIDLER');
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
        thread.CRM_Related_Object__c=request.Id;
        insert thread;
        Test.startTest();
        List<Thread__c> result=[SELECT Id FROM Thread__c WHERE CRM_Related_Object__c = :request.Id AND CRM_Type__c ='HOT_BRUKER-TOLK'];
        List<Thread__c> t = HOT_MessageHelper.getSingleThread(request.Id, 'HOT_BRUKER-TOLK');
        Test.stopTest();
        System.assertEquals(t.size(),result.size());
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
        thread.CRM_Related_Object__c=request.Id;
        HOT_DatabaseOperations.insertRecords(thread);
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getSingleThread(thread.Id, 'HOT_BRUKER-FORMIDLER');
        Test.stopTest();
        System.assertEquals(t.size(),0);
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
        thread.CRM_Related_Object__c=request.Id;
        HOT_DatabaseOperations.insertRecords(thread);

        Thread__c thread2 = new Thread__c();
        thread2.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        thread2.CRM_Related_Object__c=request.Id;
        HOT_DatabaseOperations.insertRecords(thread2);

        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreads(request.Id);
        Test.stopTest();
        System.assertEquals(t.size(),2);
    }
    @isTest
    static void getThreadFromIdTest() {
        Thread__c thread = new Thread__c();
        insert thread;
        Test.startTest();
        List<Thread__c> t = HOT_MessageHelper.getThreadFromThreadId(thread.Id);
        Test.stopTest();
         System.assertEquals(t.size(),1);
    }
    @isTest
    static void createThread() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(request.Id, acc.Id);
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
        sa.Subject='Hei';
        sa.HOT_Account__c=acc.Id;
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
        WorkOrderLineItem woli=HOT_TestDataFactory.createWorkOrderLineItem(workOrder,workType);
        insert woli;
        ServiceAppointment sa=HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject='TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId=acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
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
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(request.Id, acc.Id,'HOT_BRUKER-FORMIDLER');
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
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(workOrder.Id, acc.Id,'HOT_BRUKER-TOLK');
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
        WorkOrderLineItem woli=HOT_TestDataFactory.createWorkOrderLineItem(workOrder,workType);
        insert woli;
        ServiceAppointment sa=HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject='TEST';
        sa.Status='Dispatched';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId=acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
       

        Test.startTest();
        insert interestedResource;
        Thread__c thread = HOT_MessageHelper.createThreadDispatcher(interestedResource.Id, acc.Id,'HOT_TOLK-FORMIDLER');
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
        WorkOrderLineItem woli=HOT_TestDataFactory.createWorkOrderLineItem(workOrder,workType);
        insert woli;
        ServiceAppointment sa=HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject='TEST';
        sa.Status='Dispatched';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.AccountId=acc.Id;
        insert resource;
        HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
       
        Test.startTest();
        insert interestedResource;
        Thread__c thread = HOT_MessageHelper.createThreadInterpreter(interestedResource.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id
        ];
        System.assertNotEquals(null, tList);
    }
    static void createThreadInterpreterServiceAppointment() {
         WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli=HOT_TestDataFactory.createWorkOrderLineItem(workOrder,workType);
        insert woli;
        ServiceAppointment sa=HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject='TEST';
        sa.Status='Dispatched';
        insert sa;
        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];
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

        user = [SELECT Id, AccountId FROM User WHERE Alias = 'userTest'];
        System.runAs(user) {
            Thread__c thread = HOT_MessageHelper.createThreadInterpreter(sa.Id);
        }

       
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :sa.Id
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
       
        List<Thread__c> tList2 = [SELECT Id,  HOT_Last_message_from__c FROM Thread__c WHERE Id=:tList.get(0).Id];
        Boolean isEmpty=tList2.get(0).HOT_Last_message_from__c==null;
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
    static void getRelatedWorkOrderIdTestWO() {
         WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
         insert request;
        request.Account__c=account.Id;
        request.Orderer__c=account.Id;
       update request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        Test.startTest();
         Map<String, String> navigationhelp2 = new Map<String, String>();
         navigationhelp2.put(workOrder.Id,'WO'); 
         Map<String, String> navigationhelp = new Map<String, String>();
         navigationhelp= HOT_MessageHelper.getRelatedWorkOrderId(workOrder.Id);
        Test.stopTest();
        System.assertEquals(navigationhelp2, navigationhelp);
    }
    //    @isTest
    // static void getRelatedWorkOrderIdTestRequest() {
    //      Test.startTest();
    //      WorkType workType = HOT_TestDataFactory.createWorkType();
    //     insert workType;
    //     Account account = HOT_TestDataFactory.createAccount(true);
    //     insert account;
    //     HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
    //      insert request;
    //     request.Account__c=account.Id;
    //     request.Orderer__c=account.Id;
    //    update request;
    //     WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
    //     workOrder.AccountId = account.Id;
    //     insert workOrder;

           
    //  Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
    //     Person__c person = HOT_TestDataFactory.createPerson();
    //     person.INT_KrrEmail__c = 'getPersonTest@nav.no';
    //     person.HOT_WorkplaceInterpreter__c = true;
    //     person.INT_Confidential__c = 'Ugradert';
    //     person.INT_FirstName__c = 'Tolk';
    //     person.INT_LastName__c = 'Bruker';
    //     insert person;

    //     Account account2 = [
    //         SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
    //         FROM Account
    //         WHERE LastName = :'Bruker'
    //     ];
    //     User user = HOT_TestDataFactory.createUser(communityProfile, account2);
    //     user.Alias = 'userTest';
    //     user.Username = 'HOT_testuser1@nav.hot.no';
    //     user.CommunityNickname = 'userTest';
    //     insert user;
    //     Test.stopTest();
    //     System.runAs(user) {
    //         Map<String, String> navigationhelp2 = new Map<String, String>();
    //         navigationhelp2.put(workOrder.Id,'WO'); 
    //         Map<String, String> navigationhelp = new Map<String, String>();
    //         navigationhelp= HOT_MessageHelper.getRelatedWorkOrderId(request.Id);
           
    //        System.assertEquals(navigationhelp2, navigationhelp);
    //     }

    // }
}
