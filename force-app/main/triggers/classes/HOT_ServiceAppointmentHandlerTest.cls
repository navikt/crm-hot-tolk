@IsTest
private class HOT_ServiceAppointmentHandlerTest {
    @TestSetup
    static void makeData() {
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0]) {
            // Creating Queues and Public Groups

            TestDataFactory.getPublicGroup('HMS Møre og Romsdal', 'group_4715');
            TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'Thread__c');
            QueuesObject qso = new QueueSObject(
                QueueID = TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'Thread__c').id,
                SobjectType = 'HOT_Request__c'
            );
            insert qso;
            qso = new QueueSObject(
                QueueID = TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'Thread__c').id,
                SobjectType = 'WorkOrder'
            );
            insert qso;
            qso = new QueueSObject(
                QueueID = TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'Thread__c').id,
                SobjectType = 'ServiceAppointment'
            );
            insert qso;

            TestDataFactory.getPublicGroup('HMS Øst-Viken', 'group_4701');
            TestDataFactory.getQueue('HMS Øst-Viken', 'queue_4701', 'Thread__c');
            qso = new QueueSObject(
                QueueID = TestDataFactory.getQueue('HMS Øst-Viken', 'queue_4701', 'Thread__c').Id,
                SobjectType = 'ServiceAppointment'
            );
            insert qso;
        }
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        // User u =[SELECT Id FROM User WHERE Name = 'user' LIMIT 1][0]
        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;
        // Account acc = [SELECT Id FROM Account WHERE Name = 'Test account' LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        serviceResource.AccountId = acc.Id;
        insert serviceResource;
        // ServiceResource resource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];
        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Name = 'Test';
        resource.Service_Resource__c = serviceResource.Id;
        insert resource;

        HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
        resourceMember.Resource__c = resource.Id;
        resourceMember.Service_Resource__c = serviceResource.Id;
        insert resourceMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.PreferredResource1__c = resource.Id;
        insert request;
        // HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        //WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        // WorkOrder workOrder = [SELECT Id FROM WorkOrder WHERE HOT_Request__r.Subject__c = 'TEST' LIMIT 1];
        /*
        ServiceAppointment sa = [
            SELECT Id, HOT_Account__c, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'TEST'
            LIMIT 1
        ];
        */
    }

    @IsTest
    static void setStatusDefaultTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;
        ServiceAppointment sa = [
            SELECT Id, Status, HOT_PreferredResource__c
            FROM ServiceAppointment
            WHERE Subject = 'TEST'
            LIMIT 1
        ];

        System.assertNotEquals(null, sa.HOT_PreferredResource__c, 'Preferred Resource is null on ServiceAppointment.');
        System.assertEquals('None', sa.Status, 'Default status was not set on ServiceAppointment.');
    }

    @IsTest
    static void setOwnerTest() {
        Group moreQueue = TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'HOT_Request__c');

        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        myTriggers.disable(HOT_RequestHandler.class);
        request.OwnerId = moreQueue.Id;
        request.NumberOfInterpreters__c = 3;
        update request;
        myTriggers.enable(HOT_RequestHandler.class);
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, OwnerId
            FROM ServiceAppointment
            WHERE Subject = 'TEST'
            LIMIT 1
        ];
        System.assertEquals(
            request.OwnerId,
            serviceAppointment.OwnerId,
            'Owner of ServiceAppointment was not set to owner of Request.'
        );
    }

    @IsTest
    public static void ownerOnThreadChangeServiceAppointmentTest() {
        Group moreQueue = TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'Thread__c');
        Group vikenQueue = TestDataFactory.getQueue('HMS Øst-Viken', 'queue_4701', 'Thread__c');

        HOT_Request__c request = [SELECT Id, OwnerId FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        request.OwnerId = moreQueue.Id;
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, OwnerId
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.OwnerId = serviceAppointment.OwnerId;
        insert thread;

        thread = [
            SELECT OwnerId, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];

        Test.startTest();
        System.assertEquals(serviceAppointment.OwnerId, thread.OwnerId, 'Owner was not set correctly');

        serviceAppointment.OwnerId = vikenQueue.Id;
        update serviceAppointment;

        thread = [
            SELECT OwnerId, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];
        Test.stopTest();

        System.assertEquals(vikenQueue.Id, thread.OwnerId, 'Owner was not set correctly');
    }

    @IsTest
    public static void dispatcherOnThreadChangeServiceAppointmentTest() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;
        HOT_Request__c request = [SELECT Id, OwnerId FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_DispatcherNew__c, Status
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        serviceAppointment.Status = 'Dispatched';

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.HOT_Dispatcher__c = serviceAppointment.HOT_DispatcherNew__c;
        insert thread;

        thread = [
            SELECT HOT_Dispatcher__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];

        Test.startTest();
        System.assertEquals(
            serviceAppointment.HOT_DispatcherNew__c,
            thread.HOT_Dispatcher__c,
            'Dispatcher was not set correctly'
        );

        serviceAppointment.HOT_DispatcherNew__c = admin.Id;
        update serviceAppointment;

        thread = [
            SELECT HOT_Dispatcher__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];
        Test.stopTest();
        System.assertEquals(
            serviceAppointment.HOT_DispatcherNew__c,
            thread.HOT_Dispatcher__c,
            'Dispatcher was not set correctly'
        );
    }

    @IsTest
    static void cancelServiceAppointment() {
        HOT_Request__c request = [SELECT Id, OwnerId FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [
            SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        sa.HOT_CanceledByInterpreter__c = true;
        update sa;

        //Checking if SA is cancelled etc
        system.assertEquals(true, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to true');

        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
        insert ar;

        sa = [
            SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
            LIMIT 1
        ];

        //Checks if HOT_CancelledByInterpreter is no longer checked
        System.assertEquals(false, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to false');
    }

    @IsTest
    static void testRemoveAssignedResourceCancel() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.NumberOfInterpreters__c = 3;
        request.Status__c = 'Godkjent';
        update request;
        Test.startTest();
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;

        sa.Status = 'Canceled';
        update sa;
        Test.stopTest();
        List<AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        sa = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :sa.id];
        System.assertEquals(0, arList.size(), 'Could not delete AR');
        System.assertEquals('Canceled', sa.Status, 'Service Appointment did not retain correct status');
    }
    @IsTest
    static void testRemoveAssignedResourceNone() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.NumberOfInterpreters__c = 3;
        request.Status__c = 'Godkjent';
        update request;

        Test.startTest();
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;

        sa.Status = 'None';
        update sa;
        Test.stopTest();
        List<AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        sa = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :sa.id];
        System.assertEquals(0, arList.size(), 'Could not delete AR');
        System.assertEquals('None', sa.Status, 'Service Appointment did not retain correct status');
    }

    @IsTest
    private static void testCreateHistoricallyAssignedResources_addResource() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

        ServiceResource resource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];
        Test.startTest();
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );

        //Added Resource
        insert assignedResource;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
    }

    @IsTest
    private static void testCreateHistoricallyAssignedResources_statusChange() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.NumberOfInterpreters__c = 3;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];

        ServiceResource serviceResource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        //Change status on ServiceAppointment
        serviceAppointment.Status = 'Dispatched';
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE Status__c = 'Tildelt'
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(
            serviceResource.Id,
            harList[0].ServiceResource__c,
            'HAR ble ikke knyttet til korrekt ressurs'
        );
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
        System.assertEquals('Tildelt', harList[0].Status__c, 'Status har ikke blitt satt korrekt på HAR');
    }
    @IsTest
    private static void testCreateHistoricallyAssignedResources_resourceChange() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.NumberOfInterpreters__c = 3;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];

        ServiceResource serviceResource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];

        User user = HOT_TestDataFactory.createUser('user2', profile);
        insert user;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource2;

        assignedResource = [
            SELECT Id, ServiceResourceId, ServiceAppointmentId
            FROM AssignedResource
            WHERE Id = :assignedResource.Id
        ];
        assignedResource.ServiceResourceId = resource2.Id;

        Test.startTest();
        update assignedResource;
        Test.stopTest();

        //Old resource
        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE Status__c = 'Tolk tatt av oppdraget'
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(
            serviceResource.Id,
            harList[0].ServiceResource__c,
            'HAR ble ikke knyttet til korrekt ressurs'
        );
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
        System.assertEquals(
            'Tolk tatt av oppdraget',
            harList[0].Status__c,
            'Status har ikke blitt satt korrekt på HAR'
        );

        //New resource
        harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE ServiceResource__c = :resource2.Id
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource2.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
    }

    @IsTest
    private static void testCreateHistoricallyAssignedResources_removedResource() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.NumberOfInterpreters__c = 3;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];

        ServiceResource serviceResource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        //Remove assigned resource
        Test.startTest();
        delete assignedResource;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE Status__c = 'Tolk tatt av oppdraget'
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(
            serviceResource.Id,
            harList[0].ServiceResource__c,
            'HAR ble ikke knyttet til korrekt ressurs'
        );
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
        System.assertEquals(
            'Tolk tatt av oppdraget',
            harList[0].Status__c,
            'Status har ikke blitt satt korrekt på HAR'
        );
    }

    @IsTest
    private static void testDoNotCreateHAR() {
        Test.startTest();

        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

        ServiceResource resource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;

        serviceAppointment.Status = 'Cancel';
        serviceAppointment.HOT_DoNotCreateHAR__c = true;
        update serviceAppointment;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
        ];
        serviceAppointment = [
            SELECT Id, HOT_DoNotCreateHAR__c
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        System.assertEquals(1, harList.size());
        System.assertEquals(false, serviceAppointment.HOT_DoNotCreateHAR__c);
    }
    @IsTest
    private static void testGetTranslatedStatus() {
        Map<String, String> correctStatuses = new Map<String, String>();
        correctStatuses.put('', '');
        correctStatuses.put('Annul', 'Annullert');
        correctStatuses.put('Canceled', 'Avlyst av bruker');
        correctStatuses.put('Cannot Complete', 'Udekket');
        correctStatuses.put('Completed', 'Dekket');
        correctStatuses.put('Dispatched', 'Tildelt');
        correctStatuses.put('In Progress', 'Pågår');
        correctStatuses.put('None', 'Åpen');
        correctStatuses.put('Released to Freelance', 'Frigitt til frilanstolker');
        correctStatuses.put('Scheduled', 'Reservert');
        for (String key : correctStatuses.keySet()) {
            System.assertEquals(correctStatuses.get(key), HOT_ServiceAppointmentHandler.getTranslatedStatus(key));
        }
    }
    @IsTest
    static void preserveScheduledTimes_onUpdate() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [
            SELECT Id, Status, SchedEndTime, SchedStartTime, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];
        datetime startTime = Datetime.now().addHours(1);
        datetime endTime = Datetime.now().addHours(2);
        sa.EarliestStartTime = startTime;
        sa.DueDate = endTime;
        sa.SchedStartTime = startTime;
        sa.SchedEndTime = endTime;
        sa.Status = 'Cannot Complete';
        update sa;

        sa = [SELECT Id, Status, SchedEndTime, SchedStartTime FROM ServiceAppointment WHERE Id = :sa.Id];

        system.assertEquals(startTime, sa.SchedStartTime, 'Start time not set!');
        system.assertEquals(endTime, sa.SchedEndTime, 'End time not set');
        system.assertEquals('Cannot Complete', sa.Status, 'Status not set');

        // Altering status to None/Åpen - should preserve start/end times
        sa.Status = 'None';
        update sa;

        sa = [SELECT Id, Status, SchedEndTime, SchedStartTime FROM ServiceAppointment WHERE Id = :sa.Id];
        system.assertEquals(startTime, sa.SchedStartTime, 'Start time not set!');
        system.assertEquals(endTime, sa.SchedEndTime, 'End time not set');
        system.assertEquals('None', sa.Status, 'Status not set');
    }

    @IsTest
    static void updateScheduledTimes_onUpdate() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;
        ServiceAppointment sa = [
            SELECT Id, EarliestStartTime, DueDate, SchedEndTime, SchedStartTime
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];
        sa.EarliestStartTime = Datetime.now().addHours(2);
        sa.DueDate = Datetime.now().addHours(3);
        update sa;

        sa = [
            SELECT Id, SchedEndTime, SchedStartTime, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];
        system.assertEquals(sa.SchedStartTime, sa.EarliestStartTime, 'SchedStart time not set!');
        system.assertEquals(sa.SchedEndTime, sa.DueDate, 'SchedEnd not set');
    }

    @IsTest
    private static void testReleaseToFreelance() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

        ServiceResource serviceResource = [SELECT Id, AccountId FROM ServiceResource LIMIT 1];

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        interestedResource.Status__c = 'Not Assigned';
        insert interestedResource;
        serviceAppointment.Status = 'Released to Freelance';
        serviceAppointment.HOT_PreferredResource__c = null;
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        ServiceAppointment releasedServiceAppointment = [
            SELECT
                Id,
                Status,
                Subject,
                HOT_FreelanceSubject__c,
                HOT_DeadlineDate__c,
                HOT_IsEmployedInterpreter__c,
                HOT_IsReleasedToFreelance__c,
                HOT_ReleaseDate__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        System.assertEquals('Released to Freelance', releasedServiceAppointment.Status, 'Failed to update status');
        System.assertEquals(
            releasedServiceAppointment.Subject,
            releasedServiceAppointment.HOT_FreelanceSubject__c,
            'Freelance Subject was not set'
        );
        System.assertEquals(
            false,
            releasedServiceAppointment.HOT_IsEmployedInterpreter__c,
            'Employed interpreter was not set to false'
        );
        System.assertEquals(
            true,
            releasedServiceAppointment.HOT_IsReleasedToFreelance__c,
            'Freelance interpreter was not set to true'
        );
        System.assertEquals(
            Date.today(),
            releasedServiceAppointment.HOT_ReleaseDate__c,
            'Release date was not set to today'
        );

        HOT_InterestedResource__c updatedInterestedResource = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResource.Id
        ];
        System.assertEquals(
            'Interested',
            updatedInterestedResource.Status__c,
            'InterestedResource status was not updated'
        );

        //Test Retract
        releasedServiceAppointment.Status = 'None';
        update releasedServiceAppointment;
        releasedServiceAppointment = [
            SELECT Id, Status, HOT_IsEmployedInterpreter__c, HOT_IsReleasedToFreelance__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals('None', releasedServiceAppointment.Status, 'Failed to update status');
        System.assertEquals(
            true,
            releasedServiceAppointment.HOT_IsEmployedInterpreter__c,
            'Employed interpreter was not set to true'
        );
        System.assertEquals(
            false,
            releasedServiceAppointment.HOT_IsReleasedToFreelance__c,
            'Freelance interpreter was not set to false'
        );
    }

    @IsTest
    public static void imageInterpreterWithoutAddressTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType('BTV');
        workType.HOT_DeveloperName__c = 'BTV';
        insert WorkType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        request.Type__c = 'ImageInterpreter';
        request.AssignmentType__c = 'Image Interpreter';
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        List<ServiceAppointment> serviceAppointment = [
            SELECT Id, Street, PostalCode, City, Country, HOT_AssignmentType__c, HOT_IsImageInterpreter__c
            FROM ServiceAppointment
            LIMIT 1
        ];

        System.assertEquals(1, serviceAppointment.size(), 'Could not set street to -');
        System.assertEquals('Bildetolkvakt', serviceAppointment[0].HOT_AssignmentType__c, 'Could not set type');
        System.assertEquals('-', serviceAppointment[0].Street, 'Could not set type');
        System.assertEquals('-', serviceAppointment[0].PostalCode, 'Could not set postal code to -');
        System.assertEquals('-', serviceAppointment[0].City, 'Could not set City to -');
        System.assertEquals('Norge', serviceAppointment[0].Country, 'Could not set cuntry to Norge');
        System.assertEquals(serviceAppointment[0].HOT_IsImageInterpreter__c, true, 'Could not set imgint');
    }

    @IsTest
    public static void serviceAppointmentCompletedWithoutActualTimes() {
        WorkType workType = HOT_TestDataFactory.createWorkType('BTV');
        workType.HOT_DeveloperName__c = 'BTV';
        insert WorkType;

        HOT_Resource__c resource = [SELECT Id FROM HOT_Resource__c WHERE Name = 'Test' LIMIT 1];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        request.PreferredResource1__c = resource.Id;
        request.NumberOfInterpreters__c = 3;
        request.Type__c = 'ImageInterpreter';
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id, Status, HOT_Request__c FROM ServiceAppointment LIMIT 1];
        serviceAppointment.Status = 'Completed';
        update serviceAppointment;
        serviceAppointment = [
            SELECT Id, ActualStartTime, ActualEndTime, SchedStartTime, SchedEndTime, HOT_IsImageInterpreter__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.ActualStartTime,
            'Could not set Actual Start Time'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.ActualEndTime,
            'Could not set Actual End Time'
        );
        System.assertEquals(serviceAppointment.HOT_IsImageInterpreter__c, true, 'Could not set imgint');
    }

    @IsTest
    public static void startHourAndEndHourSameTimeAsScheduledDateTimes() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, EarliestStartTime, DueDate, HOT_StartHour__c, HOT_EndHour__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.EarliestStartTime = DateTime.now();
        serviceAppointment.DueDate = DateTime.now();
        update serviceAppointment;
        serviceAppointment = [
            SELECT Id, EarliestStartTime, DueDate, HOT_StartHour__c, HOT_EndHour__c
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(
            serviceAppointment.EarliestStartTime.format('HH', 'Europe/Oslo'),
            serviceAppointment.HOT_StartHour__c,
            'Start time ble ikke satt riktig'
        );
        System.assertEquals(
            serviceAppointment.DueDate.format('HH', 'Europe/Oslo'),
            serviceAppointment.HOT_EndHour__c,
            'End time ble ikke satt riktig'
        );
    }

    @IsTest
    public static void addContentDocumentLinkToServiceAppointment() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_Request__c, ParentRecordId
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        ContentVersion contentVersion = new ContentVersion(
            Title = 'a picture',
            PathOnClient = 'Pic.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = request.Id
        );
        insert contentDocumentLink;

        ServiceAppointment serviceAppointmentCopy = serviceAppointment.Clone(false, true, false, false);
        Test.startTest();
        insert serviceAppointmentCopy;
        Test.stopTest();

        ContentDocumentLink contentDocumentLink_ServiceAppointment = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :serviceAppointmentCopy.Id
            LIMIT 1
        ];

        Id requestContentDocumentid = contentDocumentLink.ContentDocumentId;
        Id serviceAppointmentContentDocumentId = contentDocumentLink_ServiceAppointment.ContentDocumentId;

        System.assertEquals(
            requestContentDocumentId,
            serviceAppointmentContentDocumentId,
            'ContentDocumentId fra request og serviceAppointment stemmer ikke overens.'
        );
    }

    @IsTest
    public static void actualTimeChanged() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, ActualStartTime, ActualEndTime
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.ActualStartTime = DateTime.now();
        serviceAppointment.ActualEndTime = DateTime.now().addHours(1);
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();
        serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.ActualStartTime,
            'Planlagt starttid ble ikke satt til faktisk starttid'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.ActualEndTime,
            'Planlagt sluttid ble ikke satt til faktisk sluttid'
        );
    }

    @IsTest
    public static void setArchiveAsOwnerTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id, OwnerId FROM ServiceAppointment LIMIT 1];

        Group archive = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'HOT Arkiv' LIMIT 1];
        System.assertNotEquals(
            archive.Id,
            serviceAppointment.OwnerId,
            'The owner was "HOT Arkiv". Should be different owner.'
        );

        Test.startTest();
        serviceAppointment.HOT_DelPol_IsHideRecord__c = true;
        update serviceAppointment;
        Test.stopTest();

        ServiceAppointment updatedServiceAppointment = [
            SELECT Id, OwnerId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals(
            archive.Id,
            updatedServiceAppointment.OwnerId,
            'The owner was not changed to "HOT Arkiv" as expected.'
        );
    }

    @IsTest
    public static void checkIfHOTAccountFieldIsEqualToAccountOnInsert() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id, AccountId, HOT_Account__c FROM ServiceAppointment LIMIT 1];
        System.assertEquals(
            serviceAppointment.AccountId,
            serviceAppointment.HOT_Account__c,
            'SA HOT_Account__c was not set correctly.'
        );
    }

    @IsTest
    public static void actualStartTimesShouldBeSchedStartTimesTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE Subject__c = 'TEST' LIMIT 1];
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, AccountId, ActualStartTime, ActualEndTime, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];

        serviceAppointment.ActualStartTime = null;
        serviceAppointment.ActualEndTime = null;
        serviceAppointment.Status = 'Completed';

        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime, Status
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.ActualStartTime,
            'Expected SchedStartTime and ActualStartTime to be the same'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.ActualEndTime,
            'Expected SchedEndTime and ActualEndTime to be the same'
        );
    }
}
