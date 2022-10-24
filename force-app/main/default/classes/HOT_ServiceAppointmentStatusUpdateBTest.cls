@isTest
public without sharing class HOT_ServiceAppointmentStatusUpdateBTest {
    @isTest
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

        Date today = Date.today();
        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        Integer i = 0;

        System.assertEquals('Cannot Complete', ls[0].Status, 'Alle skulle ha blitt omgort til udekket' + ls.size());
        System.assertEquals('Cannot Complete', ls[1].Status, 'Alle skulle ha blitt omgort til udekket' + ls.size());
        System.assertEquals('Cannot Complete', ls[2].Status, 'Alle skulle ha blitt omgort til udekket' + ls.size());
        System.assertEquals('Cannot Complete', ls[3].Status, 'Alle skulle ha blitt omgort til udekket' + ls.size());
        System.assertEquals('Cannot Complete', ls[4].Status, 'Alle skulle ha blitt omgort til udekket' + ls.size());
        System.assertEquals('Cannot Complete', ls[5].Status, 'Alle skulle ha blitt omgort til udekket' + ls.size());
    }
    @isTest
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
        }
        update saList;

        HOT_ServiceAppointmentStatusUpdateBatch instance = new HOT_ServiceAppointmentStatusUpdateBatch();
        database.executebatch(instance);
        Test.stopTest();

        Date today = Date.today();
        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        Integer i = 0;

        System.assertEquals('None', ls[0].Status, 'Skulle ikke blitt endret' + ls.size());
        System.assertEquals('None', ls[1].Status, 'Skulle ikke blitt endret' + ls.size());
        System.assertEquals('None', ls[2].Status, 'Skulle ikke blitt endret' + ls.size());
        System.assertEquals('None', ls[3].Status, 'Skulle ikke blitt endret' + ls.size());
        System.assertEquals('None', ls[4].Status, 'Skulle ikke blitt endret' + ls.size());
        System.assertEquals('None', ls[5].Status, 'Skulle ikke blitt endret' + ls.size());
    }
    @isTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
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
