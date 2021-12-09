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
}
