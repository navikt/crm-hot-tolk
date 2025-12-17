@IsTest
private class HOT_WorkOrderListControllerTest {
    @testSetup
    static void setup() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (admin.UserRoleId == null) {
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
            admin.UserRoleId = role.Id;
            update admin;
        }
    }

    @IsTest
    static void getMyWorkOrdersTest() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

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
        account.OwnerId = admin.Id;
        update account;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('WorkOrderListController', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        request.NumberOfInterpreters__c = 2;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;

        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, Status, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];
        ServiceAppointment serviceAppointment = serviceAppointments[0];
        ServiceAppointment serviceAppointment2 = serviceAppointments[1];
        serviceAppointment2.SchedStartTime = serviceAppointment.SchedStartTime.addDays(1);
        serviceAppointment2.SchedEndTime = serviceAppointment.SchedEndTime.addDays(1);
        update serviceAppointments;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        assignedResources.add(assignedResource);
        serviceAppointment.Status = 'Dispatched';
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            serviceResource.Id
        );
        assignedResources.add(assignedResource2);
        serviceAppointment2.Status = 'Dispatched';
        insert assignedResources;
        update serviceAppointments;

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
        Test.stopTest();

        System.runAs(user) {
            List<WorkOrder> workOrders = HOT_WorkOrderListController.getMyWorkOrders();
            System.assertEquals(1, workOrders.size(), 'Could not get all my workOrders');
        }
    }

    @IsTest
    static void getWorkOrdersFromRequestTest() {
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

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
        account.OwnerId = admin.Id;
        update account;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('WorkOrderListController', workType);
        request.Account__c = account.Id;
        request.Orderer__c = account.Id;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;

        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        Test.startTest();
        insert assignedResource;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

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
        Test.stopTest();

        user = [SELECT Id, AccountId FROM User WHERE Alias = 'userTest'];
        request = [SELECT Id, Name FROM HOT_Request__c WHERE Account__c = :user.AccountId LIMIT 1];
        System.runAs(user) {
            List<WorkOrder> workOrders = HOT_WorkOrderListController.getWorkOrdersFromRequest((String) request.Name);
            System.assertEquals(1, workOrders.size(), 'Could not get workOrders from Request');
        }
    }

    @IsTest
    static void getThreadInterpreterIdTest() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = workOrder.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        insert t;
        Test.stopTest();
        String threadId = HOT_WorkOrderListController.getThreadInterpreterId(workOrder.Id);
        System.assertEquals(t.Id, threadId, 'Could not find the thread Id');
    }

    @IsTest
    static void getServiceAppointmentsIdsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;
        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = workOrder.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        insert t;

        Test.startTest();
        List<ServiceAppointment> saList = HOT_WorkOrderListController.getServiceAppointmentsIds(workOrder.Id);
        Test.stopTest();
    }

    @IsTest
    static void getMyWorkOrdersAndRelatedRequestTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;
        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = workOrder.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        insert t;

        Test.startTest();
        Boolean b = true;
        List<WorkOrder> woList = HOT_WorkOrderListController.getMyWorkOrdersAndRelatedRequest(b);
        Test.stopTest();
    }
}
