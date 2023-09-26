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
        insert request;
        // To create child records
        request.Status__c = 'Godkjent';
        update request;
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
        serviceResource.HOT_MobilePhone__c = '12345678';
        insert serviceResource;
    }

    @isTest
    static void interpreterNamesByWorkOrderIdsTest() {
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate
            FROM WorkOrder
        ];
        HOT_ReminderSMSService.interpreterNamesByWorkOrderIds(workOrders);
    }

    @isTest
    static void reminderSMSTest() {
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate
            FROM WorkOrder
        ];
        HOT_ReminderSMSService.reminderSMS(workOrders);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
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
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSOnNewWantedSRTest() {
        ServiceResource serviceResource = [SELECT Id, Name FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(
            ServiceResource__c = serviceResource.Id,
            Status__c = 'Wanted',
            ServiceAppointment__c = serviceAppointment.Id
        );
        insert interestedResource;

        List<HOT_InterestedResource__c> irList = [SELECT Id FROM HOT_InterestedResource__c];
        Set<Id> irIds = new Set<Id>();
        for (HOT_InterestedResource__c ir : irList) {
            irIds.add(ir.Id);
        }
        HOT_ReminderSMSService.sendSMSOnNewWantedSR(irIds);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
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
    static void sendSMSOnNewMessageInterpreterTest() {
        User user = [SELECT Id FROM User LIMIT 1];

        Thread__c thread = HOT_TestDataFactory.createThread();
        insert thread;

        Test.startTest();
        HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(user.Id, thread.Id);
        Test.stopTest();

        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
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
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
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
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
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
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c][0];
        request.Type__c = 'Me';
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
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c][0];
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
}
