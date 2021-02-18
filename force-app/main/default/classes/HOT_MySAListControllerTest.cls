@isTest
private class HOT_MySAListControllerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest(
            'HOT_MySAListControllerTest',
            workType
        );
        insert request;
        request.Status__c = 'Godkjent';
        update request;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(
            UserInfo.getUserId()
        );
        insert serviceResource;
        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
            LIMIT 1
        ];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;
    }
    @isTest
    static void getMyServiceAppointmentsTest() {
        List<ServiceAppointment> myServiceAppointments = HOT_MyServiceAppointmentListController.getMyServiceAppointments();
        System.assertEquals(
            1,
            myServiceAppointments.size(),
            'Could not fetch my ServiceAppointments'
        );
    }
    @isTest
    static void getParentWorkOrderLineItemsTest() {
        List<WorkOrderLineItem> workOrderLineItem = HOT_MyServiceAppointmentListController.getParentWorkOrderLineItems();
        System.assertEquals(
            1,
            workOrderLineItem.size(),
            'Could not fetch parent WorkOrderLineItems'
        );
    }
}
