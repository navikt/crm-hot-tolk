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
        insert request;
        // To create child records
        request.Status__c = 'Godkjent';
        update request;
        WorkOrder workOrder = [SELECT Id, Status, StartDate, EndDate FROM WorkOrder];
        workOrder.Status = 'Dispatched';
        update workOrder;
        workOrder.StartDate = workOrder.StartDate.addDays(-2);
        workOrder.EndDate = workOrder.EndDate.addDays(-2);
        update workOrder;
    }

    @isTest
    static void testMethod1() {
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate
            FROM WorkOrder
        ];
        HOT_ReminderSMSService.reminderSMS(workOrders);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }
}
