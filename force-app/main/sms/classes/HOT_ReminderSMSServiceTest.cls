@isTest
private class HOT_ReminderSMSServiceTest {
    @testSetup
    static void setup() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrMobilePhone__c = '00000000';
        person.HOT_NotificationChannel__c = 'SMS';
        insert person;
        Account account = [SELECT Id FROM Account];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.StartTime__c = request.StartTime__c.addDays(3);
        request.EndTime__c = request.EndTime__c.addDays(3);
        request.OrdererPhone__c = '00000000';
        request.IsOrdererWantStatusUpdateOnSMS__c = true;
        request.Orderer__c = account.Id;
        insert request;

        // To create child records
        request.Status__c = 'Godkjent';
        update request;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        request2.Account__c = account.Id;
        request2.StartTime__c = request2.StartTime__c.addDays(3);
        request2.EndTime__c = request2.EndTime__c.addDays(3);
        request2.OrdererPhone__c = '00000000';
        request2.IsOrdererWantStatusUpdateOnSMS__c = true;
        request2.Orderer__c = account.Id;
        request2.NumberOfInterpreters__c = 3;
        insert request2;

        // To create child records
        request2.Status__c = 'Godkjent';
        update request2;

        WorkOrder workOrder = [
            SELECT
                Id,
                Status,
                Account.CRM_Person__r.HOT_NotificationChannel__c,
                Account.CRM_Person__r.INT_KrrMobilePhone__c,
                StartDate,
                EndDate,
                HOT_Request__r.IsNotNotifyAccount__c
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
        ];
        workOrder.Status = 'Dispatched';
        workOrder.StartDate = workOrder.StartDate.addDays(-2);
        workOrder.EndDate = workOrder.EndDate.addDays(-2);
        update workOrder;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        insert serviceResource;
    }

    @isTest
    static void reminderSMSTest() {
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate
            FROM WorkOrder
        ];
        HOT_ReminderSMSService.reminderSMS(workOrders);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void notifyUserOnOrderSMSTest() {
        List<HOT_Request__c> requests = [
            SELECT
                Id,
                Account__c,
                IsSerieoppdrag__c,
                SeriesPeriod__c,
                Account__r.CRM_Person__r.INT_KrrMobilePhone__c,
                IsNotifyUserOnOrder__c,
                StartTime__c,
                EndTime__c
            FROM HOT_Request__c
        ];
        HOT_ReminderSMSService.notifyUserOnOrderSMS(requests);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }
    @isTest
    static void notifyUserOnOrderSeriesSMSTest() {
        Test.startTest();
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrMobilePhone__c = '00000000';
        person.HOT_NotificationChannel__c = 'SMS';
        insert person;
        Account account = [SELECT Id FROM Account LIMIT 1];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = account.Id;
        request.Account__c = account.Id;
        request.NumberOfWorkOrders__c = 2;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        // To create child records
        request.Status__c = 'Godkjent';
        update request;

        List<HOT_Request__c> requests = [
            SELECT
                Id,
                Account__c,
                IsSerieoppdrag__c,
                SeriesPeriod__c,
                Account__r.CRM_Person__r.INT_KrrMobilePhone__c,
                IsNotifyUserOnOrder__c,
                StartTime__c,
                EndTime__c
            FROM HOT_Request__c
            WHERE Id = :request.Id AND IsSerieoppdrag__c = TRUE
        ];
        HOT_ReminderSMSService.notifyUserOnOrderSMS(requests);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        Test.stopTest();
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSToOrdererOnStatusUpdateTest() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                HOT_Request__r.Type__c,
                StartDate,
                EndDate,
                HOT_Request__r.IsNotNotifyAccount__c,
                Status,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSToInterpreterOnScreenInterpretationTest() {
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        HOT_ReminderSMSService.sendSMSToInterpreterOnScreenInterpretation(saIds);
        Test.stopTest();
    }
    @isTest
    static void sendSMSToInterpreterOnTimeChangedTest() {
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        HOT_ReminderSMSService.sendSMSToInterpreterOnTimeChanged(saIds);
        Test.stopTest();
    }
    @isTest
    static void sendSMSToInterpreterOnAddressChangedTest() {
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        HOT_ReminderSMSService.sendSMSToInterpreterOnAddressChanged(saIds);
        Test.stopTest();
    }
    @isTest
    static void sendSMSToInterpreterOnAddedOrChangedTest() {
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        HOT_ReminderSMSService.sendSMSToInterpreterOnAddedOrChanged(saIds);
        Test.stopTest();
    }
    @isTest
    static void sendSMSToInterpreterOnResourceChangedTest() {
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        HOT_ReminderSMSService.sendSMSToInterpreterOnResourceChanged(saIds);
        Test.stopTest();
    }

    @isTest
    static void sendSMSOnNewWantedSRTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        insert ir;

        Set<Id> irIds = (new Map<Id, HOT_InterestedResource__c>([SELECT Id FROM HOT_InterestedResource__c LIMIT 1]))
            .keySet();

        Test.startTest();
        HOT_ReminderSMSService.sendSMSOnNewWantedSR(irIds);
        Test.stopTest();
    }

    @isTest
    static void sendSMSOnInterpreterChangeTest() {
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];

        Set<Id> workOrderIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            workOrderIds.add(wo.Id);
        }
        Test.startTest();
        HOT_ReminderSMSService.sendSMSOnInterpreterChange(workOrderIds, 'Tolk Tolkersen');
        Test.stopTest();

        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSToOrdererOnStatusUpdateTest2() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                HOT_Request__r.Type__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSToOrdererOnStatusUpdateTestInterpreterNames() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                HOT_Request__r.Type__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c,
                Account.CRM_Person__r.INT_KrrMobilePhone__c
            FROM WorkOrder
        ];

        ServiceResource interpreter = [SELECT Id, Name FROM ServiceResource LIMIT 1];
        interpreter.Name = 'InterpreterName';

        HOT_DatabaseOperations.updateRecords(interpreter);

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_ServiceResource__c, Status
            FROM ServiceAppointment
        ];

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_ServiceResource__c = interpreter.Id;
            serviceAppointment.Status = 'Dispatched';
        }

        HOT_DatabaseOperations.updateRecords(serviceAppointments);

        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);

        String message = [SELECT Id, Message__c FROM SMS__c LIMIT 1].Message__c;

        System.assert(message.contains('InterpreterName'), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSToOrdererOnStatusUpdateSMSToAccountTest() {
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c][0];
        request.Type__c = 'Me';
        request.Orderer__c = account.Id;
        update request;
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                Account.CRM_Person__r.INT_KrrMobilePhone__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.Type__c,
                HOT_Request__r.OrdererPhone__c,
                StartDate,
                EndDate,
                HOT_Request__r.IsNotNotifyAccount__c,
                Status,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        String personPhoneNumber = workOrders[0].Account.CRM_Person__r.INT_KrrMobilePhone__c;
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        String smsPhoneNumber = [SELECT Id, Recipient__c FROM SMS__c LIMIT 1].Recipient__c;
        System.assertEquals(personPhoneNumber, smsPhoneNumber, 'SMS was not sent to the user');
    }

    @isTest
    static void sendSMSToOrdererOnStatusUpdateSMSToOtherOrdererTest() {
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c][0];
        request.Orderer__c = account.Id;
        update request;
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                Account.CRM_Person__r.INT_KrrMobilePhone__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.Type__c,
                HOT_Request__r.OrdererPhone__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        String orderPhoneNumber = workOrders[0].HOT_Request__r.OrdererPhone__c;
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        String smsPhoneNumber = [SELECT Id, Recipient__c FROM SMS__c LIMIT 1].Recipient__c;

        System.assertEquals(orderPhoneNumber, smsPhoneNumber, 'SMS was not sent to the user');
    }
    @isTest
    public static void testSendSMSOnNewMessage() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = personAccount.Id;
        request.StartTime__c = request.StartTime__c.addDays(3);
        request.EndTime__c = request.EndTime__c.addDays(3);
        request.Orderer__c = personAccount.Id;
        insert request;
        Test.startTest();
        Thread__c thread1 = new Thread__c(
            CRM_Account__c = personAccount.Id,
            CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR'
        );
        insert thread1;

        Thread__c thread2 = new Thread__c(
            CRM_Account__c = personAccount.Id,
            CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR'
        );
        insert thread2;

        Set<Id> threadIds = new Set<Id>{ thread1.Id, thread2.Id };

        HOT_ReminderSMSService.sendSMSOnNewMessage(threadIds);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        Test.stopTest();
        System.assertEquals(0, smsList.size(), 'Should not created SMS');
    }
}
