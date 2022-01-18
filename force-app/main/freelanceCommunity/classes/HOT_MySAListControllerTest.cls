@isTest
private class HOT_MySAListControllerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTest', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;
    }
    @isTest
    static void getMyServiceAppointmentsTest() {
        List<ServiceAppointment> myServiceAppointment = [SELECT Id, Status FROM ServiceAppointment];
        System.assertEquals(1, myServiceAppointment.size(), 'Could not fetch my ServiceAppointment ');

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Dispatched';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            1,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Dispatched"'
        );

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Completed';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            1,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Completed"'
        );

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Cancelled';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            0,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Cancelled"'
        );

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Cannot Complete';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            0,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Cannot Completed"'
        );
    }
    @isTest
    static void getParentWorkOrderLineItemsTest() {
        List<WorkOrderLineItem> workOrderLineItem = HOT_MyServiceAppointmentListController.getParentWorkOrderLineItems();
        System.assertEquals(1, workOrderLineItem.size(), 'Could not fetch parent WorkOrderLineItems');
    }

    @isTest
    static void getMyServiceAppointmentsTestOldSA() {
        ServiceAppointment myServiceAppointment = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];

        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTestnewSA', workType);
        insert request;
        request.SeriesEndDate__c = System.today() + 25;
        request.Status__c = 'Godkjent';
        update request;

        List<ServiceAppointment> myServiceAppointmentsbefore = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(1, myServiceAppointmentsbefore.size(), 'Expected one service appointment');

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTestOldSA', workType);
        insert request2;
        request2.SeriesEndDate__c = System.today() - (365 * 3 + 7);
        request2.Status__c = 'Godkjent';
        update request2;

        List<ServiceAppointment> myServiceAppointmentsafter = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            1,
            myServiceAppointmentsafter.size(),
            'Expected one service appointment after inserting another with a date older than 3 years.'
        );
    }
}
