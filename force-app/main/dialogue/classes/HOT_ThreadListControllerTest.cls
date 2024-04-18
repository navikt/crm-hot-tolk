@IsTest
public class HOT_ThreadListControllerTest {
    @TestSetup
    static void makeData() {
        Person__c person = HOT_TestDataFactory.createPerson('01010112345');
        insert person;
        Account account = [SELECT Id FROM Account];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        insert request;

        Thread__c t = new Thread__c();
        t.HOT_Request__c = request.Id;

        Thread__c t2 = new Thread__c();
        t2.HOT_Request__c = request.Id;

        Thread__c t3 = new Thread__c();
        t3.HOT_Request__c = request.Id;

        HOT_DIALOG_TestDataFactory.createRecordList(new List<Thread__c>{ t, t2, t3 });
    }

    @IsTest
    public static void getMyThreadsTest() {
        List<Thread__c> threadList = HOT_ThreadListController.getMyThreads();

        System.assertEquals(0, threadList.size(), 'Could not get my threads'); // Can't get current running user in test
    }
    @IsTest
    public static void getMyThreadsIRTest() {
        List<Thread__c> threadList = HOT_ThreadListController.getMyThreadsIR();

        System.assertEquals(0, threadList.size(), 'Could not get my threads'); // Can't get current running user in test
    }
    @IsTest
    public static void getMyThreadsIRServiceResourceTest() {
        User admin = [SELECT Id, AccountId, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;

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

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, serviceResource.Id);
        ir.Status__c = 'Assigned';
        insert ir;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);

        Test.startTest();
        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = ir.Id;
        t.CRM_Account__c = admin.AccountId;
        t.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        insert t;
        Message__c message = new Message__c();
        message.CRM_Thread__c = t.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        message.HOT_User_Role__c = HOT_MessageHelper.getUserProfileAndName();
        insert message;
        Test.stopTest();

        List<Thread__c> threadList = HOT_ThreadListController.getMyThreadsIR();

        System.assertEquals(1, threadList.size(), 'Could not get my threads'); // Can't get current running user in test
    }
    @IsTest
    public static void getMyThreadsFreelanceServiceResourceTest() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;

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

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, serviceResource.Id);
        ir.Status__c = 'Assigned';
        insert ir;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = workOrder.Id;
        insert t;
        Message__c message = new Message__c();
        message.CRM_Thread__c = t.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        insert message;

        List<Thread__c> threadList = HOT_ThreadListController.getMyThreadsFreelance();

        System.assertEquals(1, threadList.size(), 'Could not get my threads'); // Can't get current running user in test
    }
}
