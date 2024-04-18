@IsTest
private class HOT_WantedSRListControllerTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        serviceResource.AccountId = personAccount.Id;
        insert serviceResource;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
        request.ServiceTerritory__c = serviceTerritory.Id;
        request.NumberOfInterpreters__c = 1;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_IsReleasedToFreelance__c, Status
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];
        serviceAppointment.HOT_IsReleasedToFreelance__c = true;
        serviceAppointment.Status = 'Released To Freelance';
        serviceAppointment.HOT_DeadlineDate__c = Date.today().addDays(3);

        update serviceAppointment;

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        interestedResource.Status__c = 'Wanted';
        insert interestedResource;

        //flertolk
        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Flertolk', workType);
        request2.ServiceTerritory__c = serviceTerritory.Id;
        request2.NumberOfInterpreters__c = 3;
        insert request2;
        request2.Status__c = 'Godkjent';
        update request2;

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_IsReleasedToFreelance__c, Status
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request2.Id
        ];
        for (ServiceAppointment sa : serviceAppointments) {
            sa.HOT_IsReleasedToFreelance__c = true;
            sa.Status = 'Released To Freelance';
            sa.HOT_DeadlineDate__c = Date.today().addDays(3);
        }

        update serviceAppointments;

        HOT_InterestedResource__c interestedResource2 = HOT_TestDataFactory.createInterestedResource(
            serviceAppointments[0].Id,
            serviceResource.Id
        );
        interestedResource2.Status__c = 'Wanted';
        insert interestedResource2;
    }
    @IsTest
    static void getWantedSTListTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
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

            List<ServiceAppointment> serviceAppointments = HOT_WantedSRListController.getWantedServiceAppointments();
            System.assertEquals(2, serviceAppointments.size(), 'Could not get the wanted appointments');
        }
    }
    @IsTest
    static void updateIRTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Bestilling'];
        HOT_InterestedResource__c ir = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :sa.Id];
        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        HOT_WantedSRListController.updateInterestedResource(sa.Id, sr.Id);

        HOT_InterestedResource__c irToCheck = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :sa.Id
        ];

        System.assertEquals('Interested', irToCheck.Status__c = 'Interested', 'Could not change the ir status');
    }
    @IsTest
    static void updateIRTestExistingIROnWo() {
        ServiceAppointment sa = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'Flertolk'
            LIMIT 1
        ];

        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        HOT_WantedSRListController.updateInterestedResource(sa.Id, sr.Id);

        List<HOT_InterestedResource__c> irToCheck = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId = :sa.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        for (HOT_InterestedResource__c ir : irToCheck) {
            System.assertEquals('Interested', ir.Status__c = 'Interested', 'Could not change the ir status');
        }
    }
    @IsTest
    static void updateIRTestExistingIROnWoChecked() {
        ServiceAppointment sa = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'Flertolk'
            LIMIT 1
        ];
        List<Id> saIds = new List<Id>();
        saIds.add(sa.Id);

        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        HOT_WantedSRListController.updateInterestedResourceChecked(saIds, sr.Id);

        List<HOT_InterestedResource__c> irToCheck = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId = :sa.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        for (HOT_InterestedResource__c ir : irToCheck) {
            System.assertEquals('Interested', ir.Status__c = 'Interested', 'Could not change the ir status');
        }
    }
    @IsTest
    static void updateIRCheckedTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Bestilling'];
        HOT_InterestedResource__c ir = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :sa.Id];
        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];

        List<Id> saIds = new List<Id>();
        saIds.add(sa.Id);

        HOT_WantedSRListController.updateInterestedResourceChecked(saIds, sr.Id);

        HOT_InterestedResource__c irToCheck = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :sa.Id
        ];

        System.assertEquals('Interested', irToCheck.Status__c = 'Interested', 'Could not change the ir status');
    }
    @IsTest
    static void declineIRTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Bestilling'];
        HOT_InterestedResource__c ir = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :sa.Id];
        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        HOT_WantedSRListController.declineInterestedResource(sa.Id, sr.Id);

        HOT_InterestedResource__c irToCheck = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :sa.Id
        ];

        System.assertEquals('Declined', irToCheck.Status__c = 'Declined', 'Could not change the ir status');
    }
    @IsTest
    static void declineIRCheckedTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Bestilling'];
        HOT_InterestedResource__c ir = [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c = :sa.Id];
        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        List<Id> saIds = new List<Id>();
        saIds.add(sa.Id);

        HOT_WantedSRListController.declineInterestedResourceChecked(saIds, sr.Id);

        HOT_InterestedResource__c irToCheck = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :sa.Id
        ];

        System.assertEquals('Declined', irToCheck.Status__c = 'Declined', 'Could not change the ir status');
    }
    @IsTest
    static void noOverlapTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
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
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        Test.startTest();
        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addDays(50);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(2);
        ServiceAppointment.SchedStartTime = Datetime.now().addDays(50);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(2);
        insert ServiceAppointment;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        //

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request2;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request2, workType);
        insert workOrder2;
        WorkOrderLineItem WorkOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert WorkOrderLineItem2;

        ServiceAppointment ServiceAppointment2 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem2);
        ServiceAppointment2.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment2.DueDate = ServiceAppointment2.EarliestStartTime.addHours(3);
        ServiceAppointment2.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment2.SchedEndTime = ServiceAppointment2.SchedStartTime.addHours(5);
        insert ServiceAppointment2;

        List<ServiceAppointment> saToCheck = new List<ServiceAppointment>();
        saToCheck.add(ServiceAppointment2);

        System.runAs(user1) {
            List<ServiceAppointment> availableSA = HOT_wantedSRListController.checkForOverlap(saToCheck);
            System.assertEquals(1, availableSA.size(), 'Should return 1 because available sa');
            Test.stopTest();
        }

    }
    @IsTest
    static void hasOverlapTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
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
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Test.startTest();
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(2);
        ServiceAppointment.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(2);
        insert ServiceAppointment;

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        //

        ServiceAppointment ServiceAppointment2 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment2.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment2.DueDate = ServiceAppointment2.EarliestStartTime.addHours(3);
        ServiceAppointment2.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment2.SchedEndTime = ServiceAppointment2.SchedStartTime.addHours(4);
        insert ServiceAppointment2;

        List<ServiceAppointment> saToCheck = new List<ServiceAppointment>();
        saToCheck.add(ServiceAppointment2);

        System.runAs(user1) {
            List<ServiceAppointment> availableSA = HOT_wantedSRListController.checkForOverlap(saToCheck);
            System.assertEquals(0, availableSA.size(), 'Should return 0 because no available sa');
        }
        Test.stopTest();
    }
    @IsTest
    static void hasOverlapTestExisting() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
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
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Test.startTest();
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(2);
        ServiceAppointment.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(2);
        insert ServiceAppointment;

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        HOT_wantedSRListController.Request req = new HOT_wantedSRListController.Request();
        req.saID = ServiceAppointment.Id;
        req.srID = resource1.Id;

        List<String> result = HOT_wantedSRListController.checkForOverlapOrExisting(
            new List<HOT_wantedSRListController.Request>{ req }
        );
        System.assertEquals('existing', result[0]);
    }
    @IsTest
    static void hasOverlapTestNoOverlap() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
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
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Test.startTest();
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(2);
        ServiceAppointment.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(2);
        insert ServiceAppointment;

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment.Id,
            resource1.Id
        );

        HOT_wantedSRListController.Request req = new HOT_wantedSRListController.Request();
        req.saID = ServiceAppointment.Id;
        req.srID = resource1.Id;

        List<String> result = HOT_wantedSRListController.checkForOverlapOrExisting(
            new List<HOT_wantedSRListController.Request>{ req }
        );
        System.assertEquals('no overlap', result[0]);
    }
}
