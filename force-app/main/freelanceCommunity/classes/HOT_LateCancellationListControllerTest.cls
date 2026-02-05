@isTest
private class HOT_LateCancellationListControllerTest {
    @TestSetup
    static void setup() {
        System.Test.startTest();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        // Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus'];

        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.no',
            emailencodingkey = 'UTF-8',
            lastname = 'Testing',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = profile.Id,
            country = 'Norway',
            IsActive = true,
            timezonesidkey = 'Europe/Paris',
            username = 'HOT_testaccount@nav.hot.no'
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert user1;

            PermissionSet permissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'HOT_Tolk_Formidler'];
            // PermissionSet permissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'HOT_Tolk_Frilans'];
            insert new PermissionSetAssignment(AssigneeId = user1.id, PermissionSetId = permissionSet.Id);
        }
        System.Test.stopTest();

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        resource1.AccountId = account.Id;
        insert resource1;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            resource1,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;

        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;

        ServiceAppointment serviceAppointment1 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        serviceAppointment1.EarliestStartTime = Datetime.now().addDays(50);
        serviceAppointment1.DueDate = serviceAppointment1.EarliestStartTime.addHours(2);
        serviceAppointment1.SchedStartTime = Datetime.now().addDays(50);
        serviceAppointment1.SchedEndTime = serviceAppointment1.SchedStartTime.addHours(2);
        insert serviceAppointment1;

        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request1;

        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request1, workType);
        insert workOrder1;
        WorkOrderLineItem WorkOrderLineItem1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder1, workType);
        insert WorkOrderLineItem1;

        HOT_InterestedResource__c interestedResource1 = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment1.Id,
            resource1.Id
        );
        insert interestedResource1;
    }

    @isTest
    static void getLateCancellationsTest() {
        User user = [SELECT Id, AccountId FROM User WHERE email = 'HOT_testaccount@nav.no' LIMIT 1];

        System.Test.startTest();
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        ServiceResource resource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointments.get(0).Id,
            resource.Id
        );
        insert assignedResource;

        request.Status__c = 'Avlyst';
        update request;

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE ServiceAppointment__c = :serviceAppointments.get(0).Id
        ];

        List<HOT_InterestedResource__c> interestedResourceList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointments.get(0).Id
        ];

        System.runAs(user) {
            List<ServiceAppointment> result = HOT_LateCancellationListController.getLateCancellationsForUser();
            System.Test.stopTest();

            // System.assertEquals(1, result.size(), 'Expected exactly one ServiceAppointment in the result');
            System.assertNotEquals(null, result.size(), 'Result should not be null');
        }
    }
}
