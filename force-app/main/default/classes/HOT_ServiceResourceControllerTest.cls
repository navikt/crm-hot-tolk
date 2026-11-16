@IsTest
private class HOT_ServiceResourceControllerTest {
    @IsTest
    static void detectsPartialAndFullOverlapUsingScheduledTimes() {
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert resource;
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory territory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert territory;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, territory);
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Overlap test', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        Datetime startTime = Datetime.now().addDays(50);
        ServiceAppointment assignedAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        assignedAppointment.ServiceTerritoryId = territory.Id;
        assignedAppointment.EarliestStartTime = startTime.addHours(-4);
        assignedAppointment.DueDate = startTime.addHours(-2);
        insert assignedAppointment;
        insert HOT_TestDataFactory.createAssignedResource(assignedAppointment.Id, resource.Id);
        update new ServiceAppointment(
            Id = assignedAppointment.Id,
            Status = 'Scheduled',
            SchedStartTime = startTime,
            SchedEndTime = startTime.addHours(2)
        );

        List<Integer> startOffsets = new List<Integer>{ -60, 0, 30, -60, 60, -120, 120, 180 };
        List<Integer> endOffsets = new List<Integer>{ 60, 120, 90, 180, 180, 0, 180, 240 };
        List<Boolean> expectedOverlaps = new List<Boolean>{ true, true, true, true, true, false, false, false };
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer i = 0; i < startOffsets.size(); i++) {
            ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
            appointment.EarliestStartTime = startTime.addDays(-1);
            appointment.DueDate = appointment.EarliestStartTime.addHours(2);
            appointments.add(appointment);
        }
        insert appointments;
        List<ServiceAppointment> scheduledAppointments = new List<ServiceAppointment>();
        for (Integer i = 0; i < appointments.size(); i++) {
            scheduledAppointments.add(
                new ServiceAppointment(
                    Id = appointments[i].Id,
                    Status = 'Scheduled',
                    SchedStartTime = startTime.addMinutes(startOffsets[i]),
                    SchedEndTime = startTime.addMinutes(endOffsets[i])
                )
            );
        }
        update scheduledAppointments;

        Test.startTest();
        for (Integer i = 0; i < appointments.size(); i++) {
            HOT_ServiceResourceController.ResourceDetails details = HOT_ServiceResourceController.getResourceDetails(
                resource.Id,
                appointments[i].Id
            );
            System.assertEquals(expectedOverlaps[i], details.hasOverlap, 'Unexpected overlap for interval ' + i);
        }
        Test.stopTest();
    }

    @IsTest
    static void returnsNoResourcesWhenNoInterpreterTypesAreSelected() {
        Test.startTest();
        List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(false, false);
        List<HOT_InterestedResource__c> interestedResources = HOT_ServiceResourceController.interestedResourcesOfServiceAppointment(
            null
        );
        Test.stopTest();

        System.assertEquals(0, resources.size(), 'No interpreter types selected should return no resources.');
        System.assertEquals(0, interestedResources.size(), 'No appointment should return no interested resources.');
    }
}
