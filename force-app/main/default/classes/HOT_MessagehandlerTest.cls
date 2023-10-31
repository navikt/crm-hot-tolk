@isTest
private class HOT_MessagehandlerTest {
    @TestSetup
    static void makeData() {
        String personAccountRecordTypeId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        Person__c person = new Person__c();
        person.INT_Confidential__c = 'UGRADERT';
        person.Name = '01010100001';
        person.INT_LastName__c = 'Test';
        person.INT_FirstName__c = 'User';
        insert person;
    }

    @isTest
    public static void messageHandlerTestWithoutDispatcher() {
        Account account = [SELECT Id, PersonContactId FROM Account];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageHandlerTestWithDispatcher() {
        Account account = [SELECT Id, PersonContactId FROM Account];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageTolkRessurskontor() {
        Account account = [SELECT Id, PersonContactId FROM Account];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR';
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageTolkFormidler() {
        Account account = [SELECT Id, PersonContactId FROM Account];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = account.PersonContactId;
        thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Account__c = account.Id;
        thread.HOT_Dispatcher__c = UserInfo.getUserId();

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = account.PersonContactId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageTolkTolk() {
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert serviceResource;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.HOT_Request__c = request.Id;
        insert serviceAppointment;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = workOrder.Id;
        thread.CRM_Thread_Type__c = 'HOT_TOLK-TOLK';

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = user.AccountId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageBrukerTolk() {
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert serviceResource;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.HOT_Request__c = request.Id;
        insert serviceAppointment;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = workOrder.Id;
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = user.AccountId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @isTest
    static void messageBrukerFormidler() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Formidler' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user1', profile);
        insert user;

        User user1 = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = request.Id;
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        thread.CRM_Account__c = user1.AccountId;

        insert thread;
        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_User__c = user.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
}
