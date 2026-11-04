@IsTest
private class HOT_ServiceResourceControllerTest {
    @IsTest
    static void detectsOverlappingAssignedAppointment() {
        verifyOverlap(1, true, true);
    }

    @IsTest
    static void ignoresAppointmentStartingAtCurrentEnd() {
        verifyOverlap(2, true, false);
    }

    @IsTest
    static void ignoresAppointmentEndingAtCurrentStart() {
        verifyOverlap(-2, true, false);
    }

    @IsTest
    static void ignoresUnassignedAppointmentAndCurrentAppointment() {
        verifyOverlap(1, false, false);
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

    private static void verifyOverlap(
        Integer startOffsetHours,
        Boolean assignOtherAppointment,
        Boolean expectedOverlap
    ) {
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert resource;
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory territory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert territory;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, territory);

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem currentLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        WorkOrderLineItem otherLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert new List<WorkOrderLineItem>{ currentLineItem, otherLineItem };

        Datetime startTime = Datetime.now().addDays(50);
        ServiceAppointment currentAppointment = HOT_TestDataFactory.createServiceAppointment(currentLineItem);
        currentAppointment.ServiceTerritoryId = territory.Id;
        currentAppointment.EarliestStartTime = startTime;
        currentAppointment.DueDate = startTime.addHours(2);
        currentAppointment.SchedStartTime = currentAppointment.EarliestStartTime;
        currentAppointment.SchedEndTime = currentAppointment.DueDate;
        ServiceAppointment otherAppointment = HOT_TestDataFactory.createServiceAppointment(otherLineItem);
        otherAppointment.ServiceTerritoryId = territory.Id;
        otherAppointment.EarliestStartTime = startTime.addHours(startOffsetHours);
        otherAppointment.DueDate = otherAppointment.EarliestStartTime.addHours(2);
        otherAppointment.SchedStartTime = otherAppointment.EarliestStartTime;
        otherAppointment.SchedEndTime = otherAppointment.DueDate;
        insert new List<ServiceAppointment>{ currentAppointment, otherAppointment };

        if (assignOtherAppointment) {
            insert HOT_TestDataFactory.createAssignedResource(otherAppointment.Id, resource.Id);
        } else {
            insert HOT_TestDataFactory.createAssignedResource(currentAppointment.Id, resource.Id);
        }

        Test.startTest();
        HOT_ServiceResourceController.ResourceDetails details = HOT_ServiceResourceController.getResourceDetails(
            resource.Id,
            currentAppointment.Id
        );
        Test.stopTest();

        System.assertEquals(expectedOverlap, details.hasOverlap, 'Overlap must use other assigned appointment times.');
    }
}
