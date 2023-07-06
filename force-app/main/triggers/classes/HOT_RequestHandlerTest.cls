@isTest
private class HOT_RequestHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('HMS Troms og Finmark', 'group_4719');
        TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'HOT_Request__c');
        TestDataFactory.getPublicGroup('HMS Nordland', 'group_4718');
        TestDataFactory.getQueue('HMS Nordland', 'queue_4718', 'HOT_Request__c');
    }

    @isTest
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

    @isTest
    private static void testSetServiceTerritoryBasedOnOwner() {
        Person__c personTromso = HOT_TestDataFactory.createPerson();
        personTromso.INT_FirstName__c = 'Tromso';
        personTromso.INT_LastName__c = 'User';
        personTromso.INT_RegionNumber__c = '54';
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

    @isTest
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

    @isTest
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

    @isTest
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

    @isTest
    public static void setSourceFieldOnClonedRequest() {
        Person__c personTromso = HOT_TestDataFactory.createPerson();
        personTromso.INT_FirstName__c = 'Tromso';
        personTromso.INT_LastName__c = 'User';
        personTromso.INT_RegionNumber__c = '54';
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

    @isTest
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

    @isTest
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

    @isTest
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

    @isTest
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
    @isTest
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
    @isTest
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
    @isTest
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
    @isTest
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
    @isTest
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
    @isTest
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
    @isTest
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
    @isTest
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
        thread.CRM_Related_Object__c=request.Id;
        thread.HOT_Request__c=request.Id;
        insert thread; 
           
        Test.startTest();
            request.Dispatcher__c=admin.Id;
            update request;
        Test.stopTest();
        Thread__c t=[SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id=:thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
    @isTest
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
        thread.CRM_Related_Object__c=workOrder1.Id;
        thread.HOT_WorkOrder__c=workOrder1.Id;
        insert thread; 
           
        Test.startTest();
            request.Dispatcher__c=admin.Id;
            update request;
        Test.stopTest();
        Thread__c t=[SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id=:thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
     @isTest
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
        thread.CRM_Related_Object__c=sa.Id;
        thread.HOT_ServiceAppointment__c=sa.Id;
        insert thread; 
           
        Test.startTest();
            request.Dispatcher__c=admin.Id;
            update request;
        Test.stopTest();
        Thread__c t=[SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id=:thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
     @isTest
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
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User user1 = new User(alias = 'TestUser', email='HOT_testaccount@nav.hot.no',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profile.Id , country='Norway',IsActive =true, timezonesidkey='Europe/Paris', username='HOT_testaccount@nav.hot.no');
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(sa.Id, resource1.Id);
        insert interestedResource;

        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;

        Thread__c thread = new Thread__c();
        thread.CRM_Related_Object__c=interestedResource.Id;
        thread.HOT_InterestedResource__c=interestedResource.Id;
        insert thread; 
           
        Test.startTest();
            request.Dispatcher__c=admin.Id;
            update request;
        Test.stopTest();
        Thread__c t=[SELECT HOT_Dispatcher__c FROM Thread__c WHERE Id=:thread.Id];
        System.AssertEquals(admin.Id, t.HOT_Dispatcher__c);
    }
    @isTest
    public static void updateWorkOrderSubjectOnRequestChange() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        
        Test.startTest();
            request.Subject__c='Ny subject';
            update request;
        Test.stopTest();
        WorkOrder wo=[SELECT Subject FROM WorkOrder WHERE Id=:workOrder.Id];
        System.AssertEquals('Ny subject', wo.Subject);
    }
    @isTest
    public static void resetNotifyDispatcher() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        
        request.IsNotifyDispatcher__c=true;
        
        Test.startTest();
            update request;
        Test.stopTest();
        HOT_Request__c requestToCheck=[SELECT IsNotifyDispatcher__c FROM HOT_Request__c WHERE Id=:request.Id];
        System.AssertEquals(false, requestToCheck.IsNotifyDispatcher__c);
    }
}
