@IsTest
public without sharing class HOT_ServiceAppointmentStatusUpdateBTest {
    @IsTest
    public static void oldServiceAppointmentsAreSupposedtoBeChanged() {
        for (Integer i = 0; i < 3; i++) {
            WorkType workType = HOT_TestDataFactory.createWorkType();
            insert workType;
            Account account = HOT_TestDataFactory.createAccount(true);
            insert account;
            HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
            insert request;
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            insert workOrder;
            WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
            insert workOrderLineItem;
            ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            sa.HOT_Request__c = request.Id;
            insert sa;
        }
        Test.startTest();

        List<ServiceAppointment> salist = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa : salist) {
            sa.Status = 'None';
            sa.SchedStartTime = Datetime.now().addDays(-2);
            sa.SchedEndTime = Datetime.now().addDays(-1);
        }
        update saList;

        HOT_ServiceAppointmentStatusUpdateBatch instance = new HOT_ServiceAppointmentStatusUpdateBatch();
        database.executebatch(instance);
        Test.stopTest();

        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        for (ServiceAppointment sa : ls) {
            System.assertEquals('Cannot Complete', sa.Status, 'Status ikke omgjort til "Udekket"');
        }
    }

    @IsTest
    public static void futureServiceAppointmentsAreNotSupposedToBeChanged() {
        for (Integer i = 0; i < 3; i++) {
            WorkType workType = HOT_TestDataFactory.createWorkType();
            insert workType;
            Account account = HOT_TestDataFactory.createAccount(true);
            insert account;
            HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
            insert request;
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            insert workOrder;
            WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
            insert workOrderLineItem;
            ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            sa.HOT_Request__c = request.Id;
            insert sa;
        }
        Test.startTest();

        List<ServiceAppointment> salist = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa : salist) {
            sa.Status = 'None';
            sa.SchedStartTime = Datetime.now().addDays(3).addHours(1);
            sa.SchedEndTime = sa.SchedStartTime.addHours(2);
        }
        update saList;

        HOT_ServiceAppointmentStatusUpdateBatch instance = new HOT_ServiceAppointmentStatusUpdateBatch();
        database.executebatch(instance);
        Test.stopTest();

        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        for (ServiceAppointment sa : ls) {
            System.assertEquals('None', sa.Status, 'Status skulle ikke blitt omgjort"');
        }
    }

    @IsTest
    public static void oldServiceAppointmentsWithWrongStatusAreNotSupposedToBeChanged() {
        for (Integer i = 0; i < 3; i++) {
            WorkType workType = HOT_TestDataFactory.createWorkType();
            insert workType;
            Account account = HOT_TestDataFactory.createAccount(true);
            insert account;
            HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
            insert request;
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            insert workOrder;
            WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
            insert workOrderLineItem;
            ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            sa.HOT_Request__c = request.Id;
            insert sa;
        }
        Test.startTest();

        List<ServiceAppointment> salist = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa : salist) {
            sa.Status = 'Canceled';
            sa.SchedStartTime = Datetime.now().addDays(-2);
            sa.SchedEndTime = Datetime.now().addDays(-1);
        }
        update saList;

        HOT_ServiceAppointmentStatusUpdateBatch instance = new HOT_ServiceAppointmentStatusUpdateBatch();
        database.executebatch(instance);
        Test.stopTest();

        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        for (ServiceAppointment sa : ls) {
            System.assertEquals('Canceled', sa.Status, 'Status skulle ikke blitt "Avlyst"');
        }
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2099';

        Test.startTest();
        String jobId = System.schedule(
            'HOT_ServiceAppointmentStatusUpdateBatch',
            cron_exp,
            new HOT_ServiceAppointmentStatusUpdateBatch()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
