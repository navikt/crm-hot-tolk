@IsTest(IsParallel=true)
private class HOT_WorkOrderHandlerTest {
    @IsTest
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
        workOrder.Status = 'Canceled';

        Test.startTest();
        insert workOrder;
        Test.stopTest();

        workOrder = [
            SELECT Id, HOT_Request__c, AccountId, Street, ServiceTerritoryId, Status
            FROM WorkOrder
            WHERE Id = :workOrder.Id
        ];

        System.assertEquals(request.Id, workOrder.HOT_Request__c, 'Could not set HOT_Request__c');
        System.assertEquals(account.Id, workOrder.AccountId, 'Could not set AccountId');
        System.assertEquals(serviceTerritory.Id, workOrder.ServiceTerritoryId, 'Could not set ServiceTerritoryId');
        System.assertEquals(request.MeetingStreet__c, workOrder.Street, 'Could not set Street');
        System.assertEquals('New', workOrder.Status, 'Could not set Status to New');
    }

    @IsTest
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

    @IsTest
    private static void testUpdateRequests() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);

        insert workOrder;
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(
            1,
            request.NumberOfWorkOrders__c,
            'Could not update NumberOfWorkOrders__c on request onInsert'
        );

        delete workOrder;
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(
            0,
            request.NumberOfWorkOrders__c,
            'Could not update NumberOfWorkOrders__c on request onDelete'
        );

        undelete workOrder;
        request = [SELECT Id, NumberOfWorkOrders__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(
            1,
            request.NumberOfWorkOrders__c,
            'Could not update NumberOfWorkOrders__c on request onUndelete'
        );
    }

    @IsTest
    private static void testUpdateWorkOrders() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.Subject = 'Wrong Subject';
        insert workOrder;

        workOrder = [SELECT Id, Subject, HOT_Request__r.Subject__c FROM WorkOrder WHERE Id = :workOrder.Id];
        System.assertEquals(
            false,
            workOrder.Subject == workOrder.HOT_Request__r.Subject__c,
            'WorkOrder fields were incorrectly set'
        );

        Test.startTest();
        HOT_WorkOrderHandler.updateWorkOrders(new List<WorkOrder>{ workOrder });
        Test.stopTest();

        workOrder = [SELECT Id, Subject, HOT_Request__r.Subject__c FROM WorkOrder WHERE Id = :workOrder.Id];
        System.assertEquals(
            true,
            workOrder.Subject == workOrder.HOT_Request__r.Subject__c,
            'WorkOrder fields could not be updated'
        );
    }

    @IsTest
    private static void testSetCancelDate() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request1;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request1, workType);
        insert workOrder1;
        workOrder1.Status = 'Canceled';

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request2;
        request2.CanceledDate__c = Date.today().addDays(-1);
        update request2;

        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request2, workType);
        insert workOrder2;
        workOrder2.Status = 'Canceled';

        Test.startTest();
        update new List<WorkOrder>{ workOrder1, workOrder2 };
        Test.stopTest();

        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(
            [
                SELECT Id, CanceledDate__c, HOT_Request__c, HOT_Request__r.CanceledDate__c
                FROM WorkOrder
                WHERE Id = :workOrder1.Id OR Id = :workOrder2.Id
            ]
        );

        System.assertEquals(
            true,
            workOrders.get(workOrder1.Id).CanceledDate__c == Date.today(),
            'Could not set CanceledDate'
        );
        System.assertEquals(
            true,
            workOrders.get(workOrder2.Id).CanceledDate__c ==
            workOrders.get(workOrder2.Id).HOT_Request__r.CanceledDate__c,
            'Could not set CanceledDate equal to request Canceled Date'
        );
        System.assertEquals(
            true,
            workOrders.get(workOrder2.Id).CanceledDate__c == Date.today().addDays(-1),
            'Could not set CanceledDate to correct CanceledDate'
        );
    }
    @IsTest
    private static void testResetNotifyDispatcher() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        List<WorkOrder> workOrders = HOT_WorkOrderHandler.resetNotifyDispatcher(new List<WorkOrder>{ workOrder });
        System.assertEquals(
            false,
            workOrders[0].HOT_IsNotifyDispatcher__c,
            'Could not reset HOT_IsNotifyDispatcher__c'
        );
    }

    @IsTest
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
        workOrder3.StartDate = workOrder3.StartDate.addDays(3);
        workOrder3.EndDate = workOrder3.EndDate.addDays(3);
        workOrders.add(workOrder3);

        Test.startTest();
        insert workOrders;

        request = [
            SELECT SeriesStartDate__c, SeriesEndDate__c, StartTime__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];

        System.assertEquals(workOrder1.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder3.EndDate.date(), request.SeriesEndDate__c);
        System.assertEquals(workOrder1.StartDate, request.StartTime__c);

        workOrder2.StartDate = workOrder1.StartDate.addDays(5);
        workOrder2.EndDate = workOrder1.EndDate.addDays(5);
        update workOrder2;

        request = [SELECT SeriesStartDate__c, SeriesEndDate__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(workOrder1.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder2.EndDate.date(), request.SeriesEndDate__c);

        workOrder1.Status = 'Canceled';
        update workOrder1;

        request = [SELECT SeriesStartDate__c, SeriesEndDate__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(workOrder3.StartDate.date(), request.SeriesStartDate__c);
        System.assertEquals(workOrder2.EndDate.date(), request.SeriesEndDate__c);
    }

    @IsTest
    public static void setArchiveAsOwnerTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        workOrder.HOT_DelPol_IsHideRecord__c = true;
        update workOrder;

        WorkOrder updatedWorkOrder = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :workOrder.Id LIMIT 1];

        Group archive = [SELECT Id FROM Group WHERE TYPE = 'Queue' AND NAME = 'HOT Arkiv' LIMIT 1];

        System.assertEquals(
            archive.Id,
            updatedWorkOrder.OwnerId,
            'The owner was not changed to "HOT Arkiv" as expected.'
        );
    }

    @IsTest
    private static void testSetDuration() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.StartDate = Datetime.now().addHours(1);
        workOrder.EndDate = Datetime.now().addHours(2);

        Test.startTest();
        insert workOrder;
        Test.stopTest();

        workOrder = [SELECT Id, Duration, EndDate FROM WorkOrder WHERE Id = :workOrder.Id];
        System.assertEquals(1.00, workOrder.Duration, 'Set Duration onBeforeInsert');

        workOrder.EndDate = workOrder.EndDate.addHours(1);
        update workOrder;

        workOrder = [SELECT Id, Duration FROM WorkOrder WHERE Id = :workOrder.Id];
        System.assertEquals(2.00, workOrder.Duration, 'Set Duration onBeforeUpdate');
    }
}
