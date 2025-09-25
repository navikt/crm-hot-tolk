@IsTest(IsParallel=true)
private class HOT_RequestApprovedHandlerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        WorkType workType2 = HOT_TestDataFactory.createWorkType();
        workType2.Name = 'Work Type Name 2';
        insert workType2;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        request.NumberOfInterpreters__c = 2;
        insert request;
    }

    @IsTest
    static void requestStatusApproved() {
        HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];

        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];

        //Checking that the FSL-records have not been created yet
        System.assertEquals(0, workOrders.size());
        System.assertEquals(0, workOrderLineItems.size());
        System.assertEquals(0, serviceAppointments.size());

        Test.startTest();
        request.Status__c = 'Godkjent';
        update request;
        Test.stopTest();

        workOrders = [SELECT Id FROM WorkOrder];
        workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        serviceAppointments = [SELECT Id FROM ServiceAppointment];
        //Checking that the FSL-records have been created
        System.assertEquals(1, workOrders.size());
        System.assertEquals(1, workOrderLineItems.size());
        System.assertEquals(2, serviceAppointments.size());
    }

    @IsTest
    static void workOrder_workOrderLineItem_serviceAppointment_Test() {
        WorkType workType = [SELECT Id FROM WorkType WHERE Name = 'Work Type Name' LIMIT 1];
        HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.HOT_NumberOfInterpreters__c = 2;
        insert workOrder;

        List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        System.assertEquals(0, workOrderLineItems.size());
        System.assertEquals(0, serviceAppointments.size());

        Test.startTest();
        request.Subject__c = 'Changed Subject';
        request.Status__c = 'Godkjent';
        update request;
        Test.stopTest();

        workOrder = [SELECT Id, Subject FROM WorkOrder];
        workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        serviceAppointments = [SELECT Id, Subject FROM ServiceAppointment];
        //Checking that the FSL-records have been created
        System.assertEquals(1, workOrderLineItems.size(), 'Could not create WorkOrderLineItems');
        System.assertEquals(2, serviceAppointments.size(), 'Could not create WorkOrderLineItems');
        System.assertEquals(request.Subject__c, WorkOrder.Subject, 'Could not update fields on WorkOrder');
        System.assertEquals(request.Subject__c, serviceAppointments[0].Subject, 'Could not update fields on WorkOrder');
    }

    @IsTest
    static void requestApproved_newWorkOrder() {
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];

        request.Status__c = 'Godkjent';
        update request;

        List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        System.assertEquals(1, workOrderLineItems.size());
        System.assertEquals(2, serviceAppointments.size());

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.HOT_NumberOfInterpreters__c = 2;

        Test.startTest();
        insert workOrder;
        Test.stopTest();

        workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        serviceAppointments = [SELECT Id FROM ServiceAppointment];
        //Checking that the FSL-records have been created
        System.assertEquals(2, workOrderLineItems.size());
        System.assertEquals(4, serviceAppointments.size());
    }

    @IsTest
    static void requestApproved2Times() {
        HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c LIMIT 1];

        request.Status__c = 'Godkjent';
        update request;

        List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        System.assertEquals(1, workOrderLineItems.size());
        System.assertEquals(2, serviceAppointments.size());

        request.Status__c = 'Åpen';
        update request;

        Test.startTest();
        request.Status__c = 'Godkjent';
        update request;
        Test.stopTest();

        workOrderLineItems = [SELECT Id FROM WorkOrderLineItem];
        serviceAppointments = [SELECT Id FROM ServiceAppointment];
        //Checking that the FSL-records have been created
        System.assertEquals(1, workOrderLineItems.size());
        System.assertEquals(2, serviceAppointments.size());
    }

    @IsTest
    static void multipleWorkTypeTest() {
        WorkType workType2 = [SELECT Id FROM WorkType WHERE Name = 'Work Type Name 2' LIMIT 1];
        HOT_Request__c request = [
            SELECT Id, Status__c, InterpretationMethodSecondary__c, NumberOfInterpretersSecondary__c
            FROM HOT_Request__c
            LIMIT 1
        ];
        request.InterpretationMethodSecondary__c = workType2.Id;
        request.NumberOfInterpretersSecondary__c = 2;
        request.Status__c = 'Godkjent';

        Test.startTest();
        update request;
        Test.stopTest();

        List<WorkOrderLineItem> workOrderLineItems = [
            SELECT Id
            FROM WorkOrderLineItem
            WHERE WorkTypeId != :workType2.Id
        ];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE WorkTypeId != :workType2.Id
        ];
        List<WorkOrderLineItem> workOrderLineItems2 = [
            SELECT Id
            FROM WorkOrderLineItem
            WHERE WorkTypeId = :workType2.Id
        ];
        List<ServiceAppointment> serviceAppointments2 = [
            SELECT Id
            FROM ServiceAppointment
            WHERE WorkTypeId = :workType2.Id
        ];
        System.assertEquals(1, workOrderLineItems.size());
        System.assertEquals(2, serviceAppointments.size());
        System.assertEquals(1, workOrderLineItems2.size());
        System.assertEquals(2, serviceAppointments2.size());
    }
}
