@isTest
public without sharing class HOT_ThreadHandlerTest {
    @TestSetup
    static void makeData() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
    }
    @isTest
    static void setThreadNameBasedOnRequestTest() {
        HOT_Request__c request = [SELECT Id, OwnerId, Subject__c FROM HOT_Request__c];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = request.Id;

        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals('SAMTALE MED BRUKER: TEST', thread.Name, 'Could not set thread Name based on request');
    }
     @isTest
    static void setThreadNameBasedOnWorkorderTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.Subject='TEST';
        insert workOrder;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_TOLK-TOLK';
        thread.CRM_Related_Object__c = workOrder.Id;
        Test.startTest();
        insert thread;
        Test.stopTest();

        Thread__c t = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals(thread.Id, t.Name, 'Could not set thread Name based on workOrder');
    }
     @isTest
    static void setThreadNameBasedOnServiceAppointmentTest() {
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
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            sa.Id,
            resource.Id
        );
        insert assignedResource;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Related_Object__c = sa.Id;
        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals('SAMTALE MED TOLK: '+sa.Subject, thread.Name, 'Could not set thread Name based on workOrder');
    }
     @isTest
    static void setThreadNameBasedOnInterestedResourceTest() {
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
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;
        HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;


        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Related_Object__c = interestedResource.Id;
        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals('SAMTALE MED TOLK: '+sa.Subject, thread.Name, 'Could not set thread Name based on workOrder');
    }
    @isTest
    static void threadLongSubjectTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Subject__c='Hei dette er en veldig lang tittel på et oppdrag. Håper den blir forkortet slik at den ikke skaper trøbbel';
        insert request;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        thread.CRM_Thread_Type__c='HOT_BRUKER-FORMIDLER';
        thread.HOT_Request__c = request.Id;
        thread.CRM_Related_Object__c = request.Id;
        Test.startTest();
        insert thread;

        Thread__c t = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];
        Test.stopTest();

        System.assertEquals('SAMTALE MED BRUKER: Hei dette er en veldig lang tittel på et oppdrag. Håper ...', t.Name, 'Could not shorten the name');
    }
    @isTest
    static void createWageClaimThreadTest() {
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
        
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c= 'HOT_BRUKER-FORMIDLER';
        thread.HOT_WageClaim__c = wageClaim.Id;
        thread.CRM_Related_Object__c = wageClaim.Id;
        Test.startTest();
        insert thread;

        List<Thread__c> t = [SELECT Id, Name FROM Thread__c WHERE CRM_Related_Object__c = :wageClaim.Id];
        Test.stopTest();

        System.assertEquals(1, t.size(), 'Did not create a thread');
    }
     @isTest
    static void createOrdererThreadTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c=personAccount.Id;
        request.Account__c=personAccount.Id;
        insert request;
    
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c= 'HOT_BESTILLER-FORMIDLER';
        thread.HOT_Request__c = request.Id;
        thread.CRM_Related_Object__c = request.Id;
        Test.startTest();
        insert thread;

        List<Thread__c> t = [SELECT Id, Name FROM Thread__c WHERE CRM_Related_Object__c = :request.Id AND CRM_Thread_Type__c= 'HOT_BESTILLER-FORMIDLER'];
        Test.stopTest();

        System.assertEquals(1, t.size(), 'Did not create a thread');
    }
       @isTest
    static void createUserOrdererThreadTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c=personAccount.Id;
        request.Account__c=personAccount.Id;
        insert request;
    
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c= 'HOT_BRUKER-BESTILLER';
        thread.HOT_Request__c = request.Id;
        thread.CRM_Related_Object__c = request.Id;
        Test.startTest();
        insert thread;

        List<Thread__c> t = [SELECT Id, Name FROM Thread__c WHERE CRM_Related_Object__c = :request.Id AND CRM_Thread_Type__c= 'HOT_BRUKER-BESTILLER'];
        Test.stopTest();

        System.assertEquals(1, t.size(), 'Did not create a thread');
    }
      @isTest
    static void createUserInterpreterThreadTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
    
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c= 'HOT_BRUKER-TOLK';
        thread.HOT_WorkOrder__c = workOrder.Id;
        thread.CRM_Related_Object__c = workOrder.Id;
        Test.startTest();
        insert thread;

        List<Thread__c> t = [SELECT Id, Name FROM Thread__c WHERE CRM_Related_Object__c = :workOrder.Id AND CRM_Thread_Type__c= 'HOT_BRUKER-TOLK'];
        Test.stopTest();

        System.assertEquals(1, t.size(), 'Did not create a thread');
    }
    @isTest
    static void createInterpreterInterpreterThreadTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
    
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c= 'HOT_TOLK-TOLK';
        thread.HOT_WorkOrder__c = workOrder.Id;
        thread.CRM_Related_Object__c = workOrder.Id;
        Test.startTest();
        insert thread;

        List<Thread__c> t = [SELECT Id, Name FROM Thread__c WHERE CRM_Related_Object__c = :workOrder.Id AND CRM_Thread_Type__c= 'HOT_TOLK-TOLK'];
        Test.stopTest();

        System.assertEquals(1, t.size(), 'Did not create a thread');
    }
}
