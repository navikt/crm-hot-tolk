@IsTest
private class HOT_ServiceResourceControllerTest {
    @TestSetup
    static void setupUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User formidler = HOT_TestDataFactory.createUser('overlap', profile);
        formidler.Username = 'overlap.' + System.now().getTime() + '@example.invalid';
        insert formidler;

        PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Formidler' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = formidler.Id, PermissionSetId = permissions.Id);
    }

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
        List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(false, false, false);
        List<ServiceResource> resourcesWithNullFlags = HOT_ServiceResourceController.getAllServiceResources(
            null,
            null,
            null
        );
        List<HOT_InterestedResource__c> interestedResources = HOT_ServiceResourceController.interestedResourcesOfServiceAppointment(
            null
        );
        Test.stopTest();

        System.assertEquals(0, resources.size(), 'No interpreter types selected should return no resources.');
        System.assertEquals(0, resourcesWithNullFlags.size(), 'Null search flags should return no resources.');
        System.assertEquals(0, interestedResources.size(), 'No appointment should return no interested resources.');
    }

    @IsTest
    static void dispatcherSearchIsStandaloneAndFiltersResources() {
        User dispatcherUser = [SELECT Id FROM User WHERE Alias = 'overlap' LIMIT 1];
        ServiceResource dispatcher = createResource(dispatcherUser.Id, 'Dispatcher');
        dispatcher.HOT_IsTjenesteleverandorDispatcher__c = true;
        ServiceResource interpreter = createResource(UserInfo.getUserId(), 'Interpreter');
        interpreter.HOT_IsEmployedInterpreter__c = true;
        interpreter.HOT_IsFreelanceInterpreter__c = true;
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        insert new List<ServiceResource>{ dispatcher, interpreter };

        Test.startTest();
        for (Boolean searchFreelances : new List<Boolean>{ false, true }) {
            for (Boolean searchEmployees : new List<Boolean>{ false, true }) {
                List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(
                    searchFreelances,
                    searchEmployees,
                    true
                );
                System.assertEquals(1, resources.size(), 'Dispatcher mode must not include other interpreters.');
                System.assertEquals(dispatcher.Id, resources[0].Id);
                System.assertEquals(true, resources[0].HOT_IsTjenesteleverandorDispatcher__c);
            }
        }

        dispatcher.IsActive = false;
        update dispatcher;
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, false, true).size());

        dispatcher.IsActive = true;
        dispatcher.CRM_Subdomain__c = null;
        update dispatcher;
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, false, true).size());

        dispatcher.CRM_Subdomain__c = 'Tolketjenesten';
        dispatcher.CRM_Domain__c = null;
        update dispatcher;
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, false, true).size());
        Test.stopTest();
    }

    @IsTest
    static void dispatcherSearchExcludesRunningUser() {
        ServiceResource dispatcher = createResource(UserInfo.getUserId(), 'Current Dispatcher');
        dispatcher.HOT_IsTjenesteleverandorDispatcher__c = true;
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        insert dispatcher;

        Test.startTest();
        List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(false, false, true);
        Test.stopTest();

        System.assertEquals(0, resources.size(), 'Dispatcher search must exclude the running user.');
    }

    @IsTest
    static void preservesInterpreterSearchesWhenDispatcherSearchIsDisabled() {
        ServiceResource interpreter = createResource(UserInfo.getUserId(), 'Interpreter');
        interpreter.HOT_IsEmployedInterpreter__c = true;
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        insert interpreter;

        Test.startTest();
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(false, true, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, true, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(false, true, null).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(null, true, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(true, false, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(true, null, false).size());

        interpreter.HOT_IsEmployedInterpreter__c = false;
        interpreter.HOT_IsFreelanceInterpreter__c = true;
        update interpreter;
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, false, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, true, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, null, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, true, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(null, true, false).size());
        Test.stopTest();
    }

    private static ServiceResource createResource(Id userId, String name) {
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(userId);
        resource.Name = name;
        resource.CRM_Domain__c = 'HOT';
        resource.CRM_Subdomain__c = 'Tolketjenesten';
        return resource;
    }
}
