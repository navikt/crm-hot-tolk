@IsTest
private class HOT_TjenesteleverandorListControllerTest {
    @TestSetup
    static void createAppointments() {
        WorkType workType = HOT_TestDataFactory.createWorkType('supplier list');
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('supplier list', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer index = 0; index < 2; index++) {
            ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            appointments.add(appointment);
        }
        insert appointments;
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = 'Released to Freelance';
        }
        update appointments;

        appointments[1].HOT_TjenesteleverandorStatus__c = 'Accepted';
        update appointments[1];
    }

    @IsTest
    static void returnsOnlyTransferredAppointments() {
        Test.startTest();
        List<ServiceAppointment> appointments = HOT_TjenesteleverandorListController.getTransferredServiceAppointments();
        Test.stopTest();

        Assert.areEqual(1, appointments.size(), 'Only the transferred appointment should be returned');
        Assert.areEqual(
            'Transferred',
            appointments[0].HOT_TjenesteleverandorStatus__c,
            'The transferred list should contain transferred appointments'
        );
        Assert.isNotNull(
            appointments[0].HOT_TjenesteleverandorDeadline__c,
            'The transferred list should include the supplier response deadline'
        );
        Assert.areEqual(
            false,
            appointments[0].HOT_IsOtherEconomicProvicer__c,
            'The list should expose the Service Appointment formula without request-owner data'
        );
        Assert.isNotNull(
            appointments[0].AppointmentNumber,
            'The list should use the standard appointment number instead of its duplicate formula'
        );
    }

    @IsTest
    static void returnsOnlyAcceptedAppointments() {
        Test.startTest();
        List<ServiceAppointment> appointments = HOT_TjenesteleverandorListController.getAcceptedServiceAppointments();
        Test.stopTest();

        Assert.areEqual(1, appointments.size(), 'Only the accepted appointment should be returned');
        Assert.areEqual(
            'Accepted',
            appointments[0].HOT_TjenesteleverandorStatus__c,
            'The accepted list should contain accepted appointments'
        );
        Assert.isNotNull(
            appointments[0].HOT_TjenesteleverandorAcceptDate__c,
            'The accepted list should include the acceptance time'
        );
        Assert.areEqual(
            false,
            appointments[0].HOT_IsOtherEconomicProvicer__c,
            'The list should expose the Service Appointment formula without request-owner data'
        );
        Assert.isNotNull(
            appointments[0].AppointmentNumber,
            'The list should use the standard appointment number instead of its duplicate formula'
        );
    }
}
