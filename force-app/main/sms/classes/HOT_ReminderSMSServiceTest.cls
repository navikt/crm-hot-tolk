@isTest
private class HOT_ReminderSMSServiceTest {
    @testSetup
    static void setup() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrMobilePhone__c = '00000000';
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
        WorkOrder workOrder = [SELECT Id, Status, StartDate, EndDate FROM WorkOrder];
        workOrder.Status = 'Dispatched';
        workOrder.StartDate = workOrder.StartDate.addDays(-2);
        workOrder.EndDate = workOrder.EndDate.addDays(-2);
        update workOrder;
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
    static void sendSMSToOtherOrdererOnStatusUpdateTest() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.OrdererPhone__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        HOT_ReminderSMSService.sendSMSToOtherOrdererOnStatusUpdate(workOrders);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @isTest
    static void sendSMSToOtherOrdererOnStatusUpdateTest2() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.OrdererPhone__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOtherOrdererOnStatusUpdate(workOrders);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }
}
