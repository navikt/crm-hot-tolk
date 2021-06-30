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
        WorkType workType = HOT_TestDataFactory.createWorkType('BTV - Bildetolkvakt');
        workType.HOT_DeveloperName__c = 'BTV';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Type__c = 'ImageInterpreter';
        insert request;

        Test.startTest();
        HOT_Request__c req = request.clone();
        insert req;
        Test.stopTest();

        // Validate isClone in memory, not from DB
        System.assertEquals(req.isClone(), true, 'Request was not a clone');
        req = [SELECT Source__c FROM HOT_Request__c WHERE Id = :req.Id];
        System.assertEquals(req.Source__c, 'Dispatcher', 'Request source is not "Dispatcher" (Formidler)');
    }
}
