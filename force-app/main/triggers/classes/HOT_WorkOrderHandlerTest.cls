@isTest
private class HOT_WorkOrderHandlerTest {
    @isTest
    private static void testSetDefaultFields() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.ServiceTerritory__c = serviceTerritory.Id;
        request.Description__c = 'Description';
        request.InterpretationStreet__c = 'Street 1';
        request.InterpretationPostalCode__c = '1111';
        request.InterpretationPostalCity__c = 'City 1';
        request.MeetingStreet__c = 'Street 2';
        request.MeetingPostalCode__c = '2222';
        request.MeetingPostalCity__c = 'City 2';
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);

        Test.startTest();
        insert workOrder;
        Test.stopTest();

        workOrder = [
            SELECT Id, HOT_Request__c, AccountId, Street, ServiceTerritoryId
            FROM WorkOrder
            WHERE Id = :workOrder.Id
        ];

        System.assertEquals(request.Id, workOrder.HOT_Request__c, 'Could not set HOT_Request__c');
        System.assertEquals(account.Id, workOrder.AccountId, 'Could not set AccountId');
        System.assertEquals(serviceTerritory.Id, workOrder.ServiceTerritoryId, 'Could not set ServiceTerritoryId');
        System.assertEquals(request.MeetingStreet__c, workOrder.Street, 'Could not set Street');
    }

    @isTest
    private static void testCreateChildRecords() {
        WorkType workType1 = HOT_TestDataFactory.createWorkType();
        insert workType1;
        WorkType workType2 = HOT_TestDataFactory.createWorkType();
        insert workType2;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType1, 1, workType2, 1);
        insert request;
        request.Status__c = 'Godkjent';

        Test.startTest();
        update request;
        Test.stopTest();

        List<WorkOrderLineItem> workOrderLineItems = [
            SELECT Id, WorkOrderId, WorkTypeId
            FROM WorkOrderLineItem
            WHERE WorkOrder.HOT_Request__c = :request.Id
        ];
        System.assertEquals(2, workOrderLineItems.size(), 'Could not create workOrderLineItems');
        System.assertEquals(
            true,
            workOrderLineItems[0].WorkOrderId == workOrderLineItems[1].WorkOrderId,
            'Could not create workOrderLineItems'
        );
        System.assertEquals(
            true,
            workOrderLineItems[0].WorkTypeId != workOrderLineItems[1].WorkTypeId,
            'Could not create workOrderLineItems'
        );
    }

    @isTest
    private static void testUpdateRequest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);

        insert workOrder1;
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(1, request.NumberOfWorkOrders__c, 'Could not update NumberOfWorkOrders__c on request onInsert');
        
        delete workOrder1;
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(0, request.NumberOfWorkOrders__c, 'Could not update NumberOfWorkOrders__c on request onDelete');
        
        undelete workOrder1;
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(1, request.NumberOfWorkOrders__c, 'Could not update NumberOfWorkOrders__c on request onUndelete');
    }

    @isTest
    private static void testSeriesStartAndEndDate() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        List<WorkOrder> workOrders = new List<WorkOrder>();

        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder1.StartDate = workOrder1.StartDate.addDays(1);
        workOrder1.EndDate = workOrder1.EndDate.addDays(1);
        workOrders.add(workOrder1);
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder2.StartDate = workOrder2.StartDate.addDays(2);
        workOrder2.EndDate = workOrder2.EndDate.addDays(2);
        workOrders.add(workOrder2);
        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder3.StartDate = workOrder1.StartDate.addDays(3);
        workOrder3.EndDate = workOrder1.EndDate.addDays(3);
        workOrders.add(workOrder3);

        Test.startTest();
        insert workOrders;

        request = [SELECT SeriesStartDate__c, SeriesEndDate__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(workOrder1.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder3.EndDate.date(), request.SeriesEndDate__c);

        workOrder2.StartDate = workOrder1.StartDate.addDays(5);
        workOrder2.EndDate = workOrder1.EndDate.addDays(5);
        update workOrder2;

        request = [SELECT SeriesStartDate__c, SeriesEndDate__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(workOrder1.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder2.EndDate.date(), request.SeriesEndDate__c);
    }
}
