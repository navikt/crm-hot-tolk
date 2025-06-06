@isTest
private class HOT_UpdateExistingRecordsTest {
    @isTest
    static void executeTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType('Interpretation');

        Person__c p = HOT_TestDataFactory.createPerson('11111111111');
        p.HOT_IsReservationAgainstNotifications__c = false;
        p.HOT_NotificationChannel__c = 'SMS';
        insert p;

        ID acc = [SELECT id FROM Account WHERE crm_person__c = :p.id].id;

        HOT_Request__c r = HOT_TestDataFactory.createRequest('Request 1', workType);
        r.StartTime__c = r.StartTime__c.addDays(3);
        r.EndTime__c = r.EndTime__c.addDays(3);
        r.OrdererPhone__c = '12345678';
        r.Orderer__c = acc;
        r.IsOrdererWantStatusUpdateOnSMS__c = true;
        r.AssignmentType__c = 'Image Interpreter';
        insert r;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(r, workType);
        insert workOrder;

        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        insert sa;

        HOT_UpdateExistingRecords instance = new HOT_UpdateExistingRecords();

        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();

        ServiceAppointment su = [SELECT Id, Country FROM ServiceAppointment WHERE id = :sa.id LIMIT 1];
        System.assertEquals('Norge', su.Country, 'The country should have been updated to Norge.');
    }
}