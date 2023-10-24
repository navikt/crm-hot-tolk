@isTest
public without sharing class HOT_ThreadDetailControllerTest {
    @isTest
    public static void getThreadDetailsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Subject__c = 'TEST';
        insert request;
        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = request.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        t.HOT_Request__c = request.Id;
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
        System.runAs(admin) {
            boolean access = HOT_ThreadDetailController.checkAccess(t.Id);
            boolean check = true;
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
    @isTest
    public static void checkFreelanceAccessHasAccess() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = workOrder.Id;
        insert t;

        System.runAs(user) {
            boolean access = HOT_ThreadDetailController.checkAccess(t.Id);
            boolean check = true;
            System.assertEquals(check, access, 'Should have access to this thread');
        }
    }
    @isTest
    public static void checkFreelanceAccessHasNoAccess() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = workOrder.Id;
        insert t;

        System.runAs(user) {
            boolean access = HOT_ThreadDetailController.checkAccess(t.Id);
            boolean check = false;
            System.assertEquals(check, access, 'Should not have access to this thread');
        }
    }
    @isTest
    public static void getThreadDetailNoAccess() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = workOrder.Id;
        insert t;

        System.runAs(user) {
            Thread__c thread = HOT_ThreadDetailController.getThreadDetails(t.Id);
            System.assertEquals(null, thread, 'Should not have access to this thread');
        }
    }
}
