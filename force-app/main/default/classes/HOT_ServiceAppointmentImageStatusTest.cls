@IsTest
public with sharing class HOT_ServiceAppointmentImageStatusTest {
    @IsTest
    public static void todaysServiceAppointmentsAreSupposedtoBeChanged() {
        for (Integer i = 0; i < 3; i++) {
            WorkType workType = HOT_TestDataFactory.createWorkType('BTV - Bildetolkvakt');
            workType.HOT_DeveloperName__c = 'BTV';
            insert workType;
            HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
            insert request;
            Account account = HOT_TestDataFactory.createAccount(true);
            insert account;
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            insert workOrder;
            WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
            insert workOrderLineItem;
            ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            sa.HOT_Request__c = request.Id;
            insert sa;
        }
        List<HOT_Request__c> requestlist = [SELECT Id, Type__c FROM HOT_Request__c];
        for (HOT_Request__c request : requestlist) {
            request.Type__c = 'ImageInterpreter';
        }
        update requestlist;

        List<ServiceAppointment> salist = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa : salist) {
            sa.Status = 'Scheduled';
            sa.SchedStartTime = Datetime.now().AddHours(-1);
            sa.SchedEndTime = sa.SchedStartTime;
        }
        update saList;
        List<ServiceAppointment> salist2 = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa2 : salist2) {
            sa2.Status = 'Dispatched';
        }
        update saList2;
        Test.startTest();

        HOT_ServiceAppointmentImageStatus instance = new HOT_ServiceAppointmentImageStatus();
        database.executebatch(instance);
        Test.stopTest();

        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        for (ServiceAppointment sa : ls) {
            System.assertEquals('Completed', sa.Status, 'Status ikke omgjort til "Dekket"');
        }
    }
    @IsTest
    public static void futureServiceAppointmentsAreNotSupposedToBeChanged() {
        for (Integer i = 0; i < 3; i++) {
            WorkType workType = HOT_TestDataFactory.createWorkType('BTV - Bildetolkvakt');
            workType.HOT_DeveloperName__c = 'BTV';
            insert workType;
            HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
            request.InterpretationMethod__c = workType.Id;
            insert request;
            Account account = HOT_TestDataFactory.createAccount(true);
            insert account;
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            insert workOrder;
            WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
            insert workOrderLineItem;
            ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            sa.HOT_Request__c = request.Id;
            insert sa;
        }
        List<HOT_Request__c> requestlist = [SELECT Id, Type__c FROM HOT_Request__c];
        for (HOT_Request__c request : requestlist) {
            request.Type__c = 'ImageInterpreter';
        }
        update requestlist;
        Test.startTest();

        List<ServiceAppointment> salist = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa : salist) {
            sa.Status = 'Scheduled';
            sa.SchedStartTime = Datetime.now().addDays(3).AddHours(1);
            sa.SchedEndTime = sa.SchedStartTime.AddHours(2);
        }
        update saList;
        List<ServiceAppointment> salist2 = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa2 : salist2) {
            sa2.Status = 'Dispatched';
        }
        update saList2;

        HOT_ServiceAppointmentImageStatus instance = new HOT_ServiceAppointmentImageStatus();
        database.executebatch(instance);
        Test.stopTest();

        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        for (ServiceAppointment sa : ls) {
            System.assertEquals('Dispatched', sa.Status, 'Status skulle ikke endres');
        }
    }
    @IsTest
    public static void wrongStatusButOldIsNotSupposedToChange() {
        for (Integer i = 0; i < 3; i++) {
            WorkType workType = HOT_TestDataFactory.createWorkType('BTV - Bildetolkvakt');
            workType.HOT_DeveloperName__c = 'BTV';
            insert workType;
            HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
            request.InterpretationMethod__c = workType.Id;
            insert request;
            Account account = HOT_TestDataFactory.createAccount(true);
            insert account;
            WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            workOrder.AccountId = account.Id;
            insert workOrder;
            WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
            insert workOrderLineItem;
            ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            sa.HOT_Request__c = request.Id;
            insert sa;
        }
        List<HOT_Request__c> requestlist = [SELECT Id, Type__c FROM HOT_Request__c];
        for (HOT_Request__c request : requestlist) {
            request.Type__c = 'ImageInterpreter';
        }
        Test.startTest();

        List<ServiceAppointment> salist = [SELECT Id, Status FROM ServiceAppointment];
        for (ServiceAppointment sa : salist) {
            sa.Status = 'Scheduled';
            sa.SchedStartTime = Datetime.now().addDays(-3);
            sa.SchedEndTime = sa.SchedStartTime.AddHours(2);
        }
        update saList;

        HOT_ServiceAppointmentImageStatus instance = new HOT_ServiceAppointmentImageStatus();
        database.executebatch(instance);
        Test.stopTest();

        List<ServiceAppointment> ls = [SELECT Id, Status FROM ServiceAppointment];

        for (ServiceAppointment sa : ls) {
            System.assertEquals('Scheduled', sa.Status, 'Status skulle ikke bli omgjort');
        }
    }
    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_ServiceAppointmentImageStatus',
            cron_exp,
            new HOT_ServiceAppointmentImageStatus()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
