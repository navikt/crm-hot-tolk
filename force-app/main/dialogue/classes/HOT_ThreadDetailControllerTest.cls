@isTest
public without sharing class HOT_ThreadDetailControllerTest {
    @isTest
    public static void getThreadDetailsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Subject__c='TEST';
        insert request;
        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c= request.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_Request__c=request.Id;
        insert t;

        Test.startTest();
        Thread__c thread = HOT_ThreadDetailController.getThreadDetails(t.Id);
        Test.stopTest();
        System.assertEquals('TEST', thread.HOT_Subject__c);
    }
     @isTest
    public static void checkFreelanceAccessWO() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;
        
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

        HOT_InterestedResource__c ir=HOT_TestDataFactory.createInterestedResource(sa.Id, serviceResource.Id);
        ir.Status__c='Assigned';
        insert ir;

        
        AssignedResource ar=HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c= workOrder.Id;
        insert t;
        System.runAs(admin) {

        boolean access = HOT_ThreadDetailController.checkAccess(t.Id);
        boolean check=true;
        System.assertEquals(check, access, 'Should have access to this thread'); 
        }
    }
   @isTest
public static void checkFreelanceAccessWC() {
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

    HOT_WageClaim__c wageclaim = HOT_TestDataFactory.createWageClaim(serviceResource);
    wageclaim.ServiceAppointment__c = sa.Id;
    insert wageclaim;

    Thread__c t = new Thread__c();
    t.CRM_Related_Object__c = wageClaim.Id;
    insert t;

    System.runAs(admin) {
        boolean access = HOT_ThreadDetailController.checkAccess(t.Id);
        boolean check = true;
        System.assertEquals(check, access, 'Should have access to this thread');
    }
}
}