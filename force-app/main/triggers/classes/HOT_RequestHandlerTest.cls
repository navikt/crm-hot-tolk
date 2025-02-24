@IsTest
private class HOT_RequestHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('HMS Troms og Finmark', 'group_4719');
        TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'HOT_Request__c');
        TestDataFactory.getPublicGroup('HMS Nordland', 'group_4718');
        TestDataFactory.getQueue('HMS Nordland', 'queue_4718', 'HOT_Request__c');
    }

    @IsTest
    private static void testStatusChangeOnReqestToAvlyst() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        // To create child records
        request.Status__c = 'Godkjent';
        update request;

        // To trigger the update of child records
        request.Status__c = 'Avlyst';
        update request;

        List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder];
        List<WorkOrderLineItem> workOrderLineItems = [SELECT Status FROM WorkOrderLineItem];
        List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment];
        request = [SELECT CanceledDate__c FROM HOT_Request__c];

        for (WorkOrder workOrder : workOrders) {
            System.assertEquals('Canceled', workOrder.Status, 'Work Order Satus was not changed to correct status');
        }
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            System.assertEquals(
                'Canceled',
                workOrderLineItem.Status,
                'Work Order Satus was not changed to correct status'
            );
        }
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            System.assertEquals(
                'Canceled',
                serviceAppointment.Status,
                'Work Order Satus was not changed to correct status'
            );
        }

        System.assertEquals(Date.today(), request.CanceledDate__c, 'Cancel data was not set correct');
    }

    @IsTest
    private static void testSetServiceTerritoryBasedOnOwner() {
        Person__c personTromso = HOT_TestDataFactory.createPerson();
        personTromso.INT_FirstName__c = 'Tromso';
        personTromso.INT_LastName__c = 'User';
        personTromso.INT_RegionNumber__c = '55';
        personTromso.INT_MunicipalityNumber__c = '5501';
        insert personTromso;
        Account accountTromso = [SELECT Id FROM Account WHERE FirstName = :personTromso.INT_FirstName__c LIMIT 1];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory tromso = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        tromso.HOT_DeveloperName__c = 'Tromso';
        tromso.Name = 'Tromso';
        insert tromso;
        ServiceTerritory Nordland = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        Nordland.HOT_DeveloperName__c = 'Nordland';
        Nordland.Name = 'Nordland';
        insert Nordland;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = accountTromso.Id;
        insert request;

        request = [SELECT OwnerId, ServiceTerritory__r.Id FROM HOT_Request__c WHERE Id = :request.Id LIMIT 1];
        System.assertEquals(
            tromso.Id,
            request.ServiceTerritory__r.Id,
            'ServiceTerritory was not properly set on creation'
        );

        Group nordlandQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'queue_4718'];
        request.OwnerId = nordlandQueue.Id;
        update request;
        request = [SELECT ServiceTerritory__r.Id FROM HOT_Request__c WHERE Id = :request.Id LIMIT 1];
        System.assertEquals(
            Nordland.Id,
            request.ServiceTerritory__r.Id,
            'ServiceTerritory was not properly set on update'
        );
    }

    @IsTest
    private static void testTriggerOfKrrIntegration() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);

        person = [SELECT Id, CRM_Account__c, INT_KrrIntegrationStatus__c FROM Person__c WHERE Id = :person.Id];
        System.assertEquals('Not Started', person.INT_KrrIntegrationStatus__c);

        request.Account__c = person.CRM_Account__c;
        insert request;

        person = [SELECT Id, CRM_Account__c, INT_KrrIntegrationStatus__c FROM Person__c WHERE Id = :person.Id];
        System.assertEquals('Queued', person.INT_KrrIntegrationStatus__c);
    }

    @IsTest
    public static void createWorkOrdersFromCommunityTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Map<String, Map<String, Long>> times = new Map<String, Map<String, Long>>();
        Map<String, Long> timeMap = new Map<String, Long>();
        timeMap.put('startTime', DateTime.now().addHours(1).getTime());
        timeMap.put('endTime', DateTime.now().addHours(2).getTime());
        timeMap.put('isNew', 1);
        times.put('1', timeMap);
        timeMap.put('startTime', DateTime.now().addDays(1).addHours(1).getTime());
        timeMap.put('endTime', DateTime.now().addDays(1).addHours(2).getTime());
        timeMap.put('isNew', 1);
        times.put('2', timeMap);
        HOT_RequestHandler.createAndUpdateWorkOrders(request.Id, times);
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder WHERE HOT_Request__c = :request.Id];
        System.assertEquals(2, workOrders.size(), 'Could not insert workOrders');
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(2, request.NumberOfWorkOrders__c, 'Could not set NumberOfWorkOrders on request');
    }

    @IsTest
    public static void setDefaultFieldsImageInterpreter() {
        WorkType workType = HOT_TestDataFactory.createWorkType('BTV - Bildetolkvakt');
        workType.HOT_DeveloperName__c = 'BTV';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.InterpretationMethod__c = null;
        request.Type__c = 'ImageInterpreter';
        insert request;
        request = [SELECT InterpretationMethod__c, AssignmentType__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals('Image Interpreter', request.AssignmentType__c, 'Could not set AssignementType');
        System.assertEquals(workType.Id, request.InterpretationMethod__c, 'Could not set InterpretationMethod');
    }

    @IsTest
    public static void setSourceFieldOnClonedRequest() {
        Person__c personTromso = HOT_TestDataFactory.createPerson();
        personTromso.INT_FirstName__c = 'Tromso';
        personTromso.INT_LastName__c = 'User';
        personTromso.INT_MunicipalityNumber__c = '5501';
        personTromso.INT_RegionNumber__c = '55';
        insert personTromso;
        Account accountTromso = [SELECT Id FROM Account WHERE FirstName = :personTromso.INT_FirstName__c LIMIT 1];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Source__c = 'Community';
        request.Account__c = accountTromso.Id;
        insert request;

        Test.startTest();
        HOT_Request__c req = request.clone();
        insert req;
        Test.stopTest();

        // Validate isClone in memory, not from DB
        System.assertEquals(req.isClone(), true, 'Request was not a clone');
        req = [SELECT Source__c FROM HOT_Request__c WHERE Id = :req.Id];
        System.assertEquals(req.Source__c, 'Community', 'Request source is not "Community" (Formidler)');
    }

    @IsTest
    public static void setArchiveAsOwnerTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Group archive = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'HOT Arkiv' LIMIT 1];
        System.assertNotEquals(archive.Id, request.OwnerId, 'The owner was "HOT Arkiv". Should be different owner.');

        Test.startTest();
        request.HOT_DelPol_IsHideRecord__c = true;
        update request;
        Test.stopTest();

        HOT_Request__c updatedRequest = [SELECT Id, OwnerId FROM HOT_Request__c WHERE Id = :request.Id LIMIT 1];
        System.assertEquals(
            archive.Id,
            updatedRequest.OwnerId,
            'The owner was not changed to "HOT Arkiv" as expected.'
        );
    }

    @IsTest
    public static void setUserInterpretationField() {
        WorkType workType = HOT_TestDataFactory.createWorkType('TS - Tegnspråk');
        workType.HOT_DeveloperName__c = 'TS';
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Source__c = 'Community';
        request.InterpretationMethod__c = null;
        request.UserInterpretationMethod__c = 'TS';

        Test.startTest();
        insert request;
        Test.stopTest();

        request = [
            SELECT InterpretationMethod__r.HOT_DeveloperName__c, UserInterpretationMethod__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];
        System.assertEquals(
            request.InterpretationMethod__r.HOT_DeveloperName__c,
            request.UserInterpretationMethod__c,
            'Request.InterpretationMethod__r.HOT_DeveloperName__c field is not equal to UserInterpretationMethod__c field.'
        );
    }

    @IsTest
    public static void userInterpretationFieldShouldNotBeSet() {
        WorkType workType = HOT_TestDataFactory.createWorkType('TS - Tegnspråk');
        workType.HOT_DeveloperName__c = 'TS';
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Source__c = 'Dispatcher';
        Account acc = HOT_TestDataFactory.createAccount(true);
        insert acc;
        request.Orderer__c = acc.Id;

        Test.startTest();
        insert request;
        Test.stopTest();

        request = [
            SELECT InterpretationMethod__r.HOT_DeveloperName__c, UserInterpretationMethod__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];
        System.assertNotEquals(
            request.InterpretationMethod__r.HOT_DeveloperName__c,
            request.UserInterpretationMethod__c,
            'InterpretationMethod__c field should not be equal to UserInterpretationMethod__c field in this case.'
        );
    }

    @IsTest
    public static void multipleRequestsApproved() {
        WorkType workType = HOT_TestDataFactory.createWorkType('TS - Tegnspråk');
        insert workType;

        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('Request 1', workType);
        insert request1;
        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Request 2', workType);
        insert request2;

        Test.startTest();
        request1.Status__c = 'Godkjent';
        request2.Status__c = 'Godkjent';

        update new List<HOT_Request__c>{ request1, request2 };
        Test.stopTest();

        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        System.assertEquals(
            2,
            serviceAppointments.size(),
            'Could not create the correct ampint of Service Appointments'
        );
    }
    @IsTest
    public static void setInterpretationAdressSameAsMeetingadress() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('Request 1', workType);
        request1.MeetingStreet__c = 'Sommerveien 2';
        request1.MeetingPostalCity__c = 'Oslo';
        request1.MeetingPostalCode__c = '0166';

        person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :person.Id];

        request1.Account__c = person.CRM_Account__c;
        insert request1;

        List<HOT_Request__c> requester = [
            SELECT InterpretationStreet__c, InterpretationPostalCode__c, InterpretationPostalCity__c
            FROM HOT_Request__c
            WHERE Id = :request1.Id
            LIMIT 1
        ];

        System.assertEquals(
            'Sommerveien 2',
            requester[0].InterpretationStreet__c,
            'Interpetration and Meeting street is not the same'
        );
        System.assertEquals(
            'Oslo',
            requester[0].InterpretationPostalCity__c,
            'Interpetration and Meeting postalcity is not the same'
        );
        System.assertEquals(
            '0166',
            requester[0].InterpretationPostalCode__c,
            'Interpetration and Meeting postalcode is not the same'
        );
    }
    @IsTest
    public static void setMeetingadressSameAsInterpretationAdress() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('Request 1', workType);
        request1.InterpretationStreet__c = 'Sommerveien 2';
        request1.InterpretationPostalCity__c = 'Oslo';
        request1.InterpretationPostalCode__c = '0166';

        person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :person.Id];

        request1.Account__c = person.CRM_Account__c;
        insert request1;

        List<HOT_Request__c> requester = [
            SELECT MeetingPostalCity__c, MeetingPostalCode__c, MeetingStreet__c
            FROM HOT_Request__c
            WHERE Id = :request1.Id
            LIMIT 1
        ];

        System.assertEquals(
            'Sommerveien 2',
            requester[0].MeetingStreet__c,
            'Interpetration and Meeting street is not the same'
        );
        System.assertEquals(
            'Oslo',
            requester[0].MeetingPostalCity__c,
            'Interpetration and Meeting postalcity is not the same'
        );
        System.assertEquals(
            '0166',
            requester[0].MeetingPostalCode__c,
            'Interpetration and Meeting postalcode is not the same'
        );
    }
    @IsTest
    public static void shouldNotSetSameAdressWhenBothIsFilled() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('Request 1', workType);
        request1.InterpretationStreet__c = 'Sommerveien 2';
        request1.InterpretationPostalCity__c = 'Oslo';
        request1.InterpretationPostalCode__c = '0166';
        request1.MeetingStreet__c = 'Tromsø 8';
        request1.MeetingPostalCity__c = 'Tromsø';
        request1.MeetingPostalCode__c = '8888';

        person = [SELECT Id, CRM_Account__c FROM Person__c WHERE Id = :person.Id];

        request1.Account__c = person.CRM_Account__c;
        insert request1;

        List<HOT_Request__c> requester = [
            SELECT
                MeetingPostalCity__c,
                MeetingPostalCode__c,
                MeetingStreet__c,
                InterpretationStreet__c,
                InterpretationPostalCode__c,
                InterpretationPostalCity__c
            FROM HOT_Request__c
            WHERE Id = :request1.Id
            LIMIT 1
        ];

        System.assertNotEquals(
            'Tromsø 8',
            requester[0].InterpretationStreet__c,
            'Both adresses was changed to the same'
        );
        System.assertNotEquals(
            'Tromsø',
            requester[0].InterpretationPostalCity__c,
            'Both adresses was changed to the same'
        );
        System.assertNotEquals(
            '8888',
            requester[0].InterpretationPostalCode__c,
            'Both adresses was changed to the same'
        );
        System.assertNotEquals('Sommerveien 2', requester[0].MeetingStreet__c, 'Both adresses was changed to the same');
        System.assertNotEquals('Oslo', requester[0].MeetingPostalCity__c, 'Both adresses was changed to the same');
        System.assertNotEquals('0166', requester[0].MeetingPostalCode__c, 'Both adresses was changed to the same');
    }
    @IsTest
    public static void shouldOnlyChangeStatusToCannotCompleteIfAllSAIsReleased() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        WorkOrderLineItem workOrderLineItem1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder1, workType);
        insert workOrderLineItem1;
        WorkOrderLineItem workOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert workOrderLineItem2;
        ServiceAppointment sa1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem1);
        sa1.HOT_Request__c = request.Id;
        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        sa2.HOT_Request__c = request.Id;
        insert sa1;
        insert sa2;

        sa1.Status = 'Released to Freelance';
        sa2.Status = 'Released to Freelance';
        update sa1;
        update sa2;
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request.Status__c = 'Udekket';
        update request;
        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Udekket', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    public static void statusIsNotSupposedToChangeBecauseSAIsNotReleasedToFreelance() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        WorkOrderLineItem workOrderLineItem1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder1, workType);
        insert workOrderLineItem1;
        WorkOrderLineItem workOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert workOrderLineItem2;
        ServiceAppointment sa1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem1);
        sa1.HOT_Request__c = request.Id;
        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        sa2.HOT_Request__c = request.Id;
        insert sa1;
        insert sa2;
        request.Status__c = 'Godkjent';
        update request;
        sa1.Status = 'Dispatched';
        sa2.Status = 'Released to Freelance';
        update sa1;
        update sa2;
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request.Status__c = 'Udekket';
        try {
            update request;
        } catch (Exception e) {
            Boolean expectedException = e.getMessage()
                    .contains(
                        'Alle oppdrag må være Frigitt til frilans, eller alle arbeidsordre må være Åpen for at du skal kunne sette hele forespørselen til Udekket.'
                    )
                ? true
                : false;
            System.AssertEquals(expectedException, true);
        }
    }
    @IsTest
    public static void statusShouldChangeWhenAllWorkOrdersAreSetToNew() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        WorkOrderLineItem workOrderLineItem1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder1, workType);
        insert workOrderLineItem1;
        WorkOrderLineItem workOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert workOrderLineItem2;
        ServiceAppointment sa1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem1);
        sa1.HOT_Request__c = request.Id;
        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        sa2.HOT_Request__c = request.Id;
        insert sa1;
        insert sa2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'New';
        workOrder2.Status = 'New';
        update workOrder1;
        update workOrder2;

        request.Status__c = 'Udekket';
        update request;
        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Udekket', request.Status__c, 'Status on the request was supposed to be changed');
    }
    @IsTest
    public static void statusShouldNotChangeWhenAllWorkOrdersAreNotSetNew() {
        //feil i den her
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        WorkOrderLineItem workOrderLineItem1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder1, workType);
        insert workOrderLineItem1;
        WorkOrderLineItem workOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert workOrderLineItem2;
        ServiceAppointment sa1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem1);
        sa1.HOT_Request__c = request.Id;
        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        sa2.HOT_Request__c = request.Id;
        insert sa1;
        insert sa2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Scheduled';
        workOrder2.Status = 'New';
        update workOrder1;
        update workOrder2;

        request.Status__c = 'Udekket';
        try {
            update request;
        } catch (Exception e) {
            Boolean expectedException = e.getMessage()
                    .contains(
                        'Alle oppdrag må være Frigitt til frilans, eller alle arbeidsordre må være Åpen for at du skal kunne sette hele forespørselen til Udekket.'
                    )
                ? true
                : false;
            System.AssertEquals(expectedException, true);
        }
    }
    @IsTest
    public static void dispatcherOnThreadChangeRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = request.Id;
        thread.HOT_Request__c = request.Id;
        insert thread;

        Test.startTest();
        request.Dispatcher__c = admin.Id;
        update request;
        Test.stopTest();
        Thread__c t = [SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id = :thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
    @IsTest
    public static void ownerOnThreadChangeRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Group tromsOgFinnmarkQueue = TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'Thread__c');

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = request.Id;
        thread.HOT_Request__c = request.Id;
        thread.OwnerId = request.OwnerId;
        insert thread;

        Test.startTest();
        thread = [SELECT OwnerId, HOT_Request__c FROM Thread__c WHERE HOT_Request__c = :request.Id];
        System.assertEquals(request.OwnerId, thread.OwnerId, 'Owner was not set correctly');

        request.OwnerId = tromsOgFinnmarkQueue.Id;
        update request;
        thread = [SELECT OwnerId, HOT_Request__c FROM Thread__c WHERE HOT_Request__c = :request.Id];
        Test.stopTest();

        System.assertEquals(tromsOgFinnmarkQueue.Id, thread.OwnerId, 'Owner was not set correctly');
    }
    @IsTest
    public static void dispatcherOnThreadChangeWorkOrder() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = workOrder1.Id;
        thread.HOT_WorkOrder__c = workOrder1.Id;
        insert thread;

        Test.startTest();
        request.Dispatcher__c = admin.Id;
        update request;
        Test.stopTest();
        Thread__c t = [SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id = :thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
    @IsTest
    public static void dispatcherOnThreadChangeSA() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        //sa.HOT_Request__c = request.Id;
        insert sa;
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = sa.Id;
        thread.HOT_ServiceAppointment__c = sa.Id;
        insert thread;

        Test.startTest();
        request.Dispatcher__c = admin.Id;
        update request;
        Test.stopTest();
        Thread__c t = [SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id = :thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
    @IsTest
    public static void dispatcherOnThreadChangeIR() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        insert sa;
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
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            sa.Id,
            resource1.Id
        );
        insert interestedResource;

        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = interestedResource.Id;
        thread.HOT_InterestedResource__c = interestedResource.Id;
        insert thread;

        Test.startTest();
        request.Dispatcher__c = admin.Id;
        update request;
        Test.stopTest();
        Thread__c t = [SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id = :thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
    @IsTest
    public static void updateWorkOrderSubjectOnRequestChange() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Test.startTest();
        request.Subject__c = 'Ny subject';
        update request;
        Test.stopTest();
        WorkOrder wo = [SELECT Subject FROM WorkOrder WHERE Id = :workOrder.Id];
        System.AssertEquals('Ny subject', wo.Subject);
    }
    @IsTest
    public static void updateWorkOrderAccountOnRequestChange() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        Account account2 = HOT_TestDataFactory.createAccount(true);
        insert account2;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Test.startTest();
        request.Account__c = account2.Id;
        update request;
        Test.stopTest();
        WorkOrder wo = [SELECT AccountId FROM WorkOrder WHERE Id = :workOrder.Id];
        System.AssertEquals(account2.Id, wo.AccountId);
    }
    @IsTest
    public static void updateWorkOrderAccountRemovedOnRequestChange() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Test.startTest();
        request.Account__c = null;
        update request;
        Test.stopTest();
        WorkOrder wo = [SELECT AccountId FROM WorkOrder WHERE Id = :workOrder.Id];
        System.AssertEquals(null, wo.AccountId);
    }
    @IsTest
    public static void resetNotifyDispatcher() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        request.IsNotifyDispatcher__c = true;

        Test.startTest();
        update request;
        Test.stopTest();
        HOT_Request__c requestToCheck = [SELECT IsNotifyDispatcher__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.AssertEquals(false, requestToCheck.IsNotifyDispatcher__c);
    }
    @IsTest
    public static void updateMeetingAdressTest() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        request.MeetingStreet__c = 'Fyrstikkaleen 1';
        request.MeetingPostalCity__c = 'Oslo';
        request.MeetingPostalCode__c = '0166';
        update request;

        WorkOrder workorderResult = [
            SELECT Address, Street, City, PostalCode
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
        ];
        Test.stopTest();
        System.AssertEquals('Fyrstikkaleen 1', workorderResult.Street, 'Street did not get updated');
        System.AssertEquals('Oslo', workorderResult.City, 'City did not get updated');
        System.AssertEquals('0166', workorderResult.PostalCode, 'Postalcode did not get updated');
    }
    @IsTest
    public static void updateInterpretationAdressTest() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        request.InterpretationPostalCode__c = '0166';
        request.InterpretationPostalCity__c = 'Oslo';
        request.InterpretationStreet__c = 'Fyrstikkaleen 1';
        update request;

        WorkOrder workorderResult = [
            SELECT HOT_InterpretationPostalCode__c, HOT_InterpretationPostalCity__c, HOT_InterpretationStreet__c
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
        ];
        Test.stopTest();
        System.AssertEquals(
            'Fyrstikkaleen 1',
            workorderResult.HOT_InterpretationStreet__c,
            'Street did not get updated'
        );
        System.AssertEquals('Oslo', workorderResult.HOT_InterpretationPostalCity__c, 'City did not get updated');
        System.AssertEquals('0166', workorderResult.HOT_InterpretationPostalCode__c, 'Postalcode did not get updated');
    }
    @IsTest
    public static void checkIfRequestCreatedCorrectlyTrueTest() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        Boolean result = HOT_RequestHandler.isErrorOnRequestCreate(request.Id);
        //Den sjekker om det ble feil ved opprettelse. False betyr at det ikke er noe feil
        System.AssertEquals(false, result, 'Should have been shown to be created correctly');
    }
    @IsTest
    public static void checkIfRequestCreatedCorrectlyFalseTest() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        Boolean result = HOT_RequestHandler.isErrorOnRequestCreate(request.Id);
        //Den sjekker om det ble feil ved opprettelse. True betyr at det er feil
        System.AssertEquals(true, result, 'Should have been shown to be not created correctly');
    }
}
