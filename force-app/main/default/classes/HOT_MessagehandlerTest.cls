@IsTest(IsParallel=true)
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

    @IsTest
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @IsTest
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('');

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @IsTest
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('HOT_TOLK-RESSURSKONTOR');

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @IsTest
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
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName('HOT_TOLK-RESSURSKONTOR');

        test.startTest();
        insert message;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(1, messages.size(), 'Could not create message');
    }
    @IsTest
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
    @IsTest
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
        HOT_ThreadHandler.setInterpreter(new List<Thread__c>{ thread });
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

    @IsTest
    static void ThreadElseTest() {
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

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR';
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        Thread__c thread2 = new Thread__c();
        thread2.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread2.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        thread2.CRM_Related_Object__c = workOrder.Id;
        insert thread2;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_From_Contact__c = user.AccountId;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = null;

        Message__c message2 = new Message__c();
        message2.CRM_Thread__c = thread2.Id;
        message2.CRM_From_Contact__c = user.AccountId;
        message2.CRM_Message_Text__c = 'Dette er en testmelding';
        message2.HOT_User_Role__c = null;

        test.startTest();
        insert message;
        insert message2;
        test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c];
        System.assertEquals(2, messages.size(), 'Could not create message');
    }
}
