@IsTest
private class HOT_AssignOrReserveSAServiceTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('AssignOrReserve', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
            LIMIT 1
        ];
        User secondUser = HOT_TestDataFactory.createUser('SecUser', profile);
        insert secondUser;

        ServiceResource firstResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        firstResource.HOT_IsFreelanceInterpreter__c = true;
        firstResource.HOT_ServiceTerritory__c = serviceTerritory.Id;

        ServiceResource secondResource = HOT_TestDataFactory.createServiceResource(secondUser.Id);
        secondResource.Name = 'Another Resource';
        secondResource.HOT_IsFreelanceInterpreter__c = true;
        secondResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert new List<ServiceResource>{ firstResource, secondResource };
        insert new List<ServiceTerritoryMember>{
            HOT_TestDataFactory.createServiceTerritoryMember(firstResource, serviceTerritory),
            HOT_TestDataFactory.createServiceTerritoryMember(secondResource, serviceTerritory)
        };

        WorkOrder workOrder = [SELECT Id FROM WorkOrder WHERE HOT_Request__c = :request.Id LIMIT 1];
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :workOrder.Id
            LIMIT 1
        ];
        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
            WHERE ParentRecordId = :workOrderLineItem.Id
            LIMIT 1
        ];
        update new ServiceAppointment(Id = serviceAppointment.Id, ServiceTerritoryId = serviceTerritory.Id);

        insert new List<HOT_InterestedResource__c>{
            HOT_TestDataFactory.createInterestedResource(serviceAppointment.Id, firstResource.Id),
            HOT_TestDataFactory.createInterestedResource(serviceAppointment.Id, secondResource.Id)
        };
    }

    @IsTest
    static void reserveFromNone_createsInitialReservation() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        ServiceResource firstResource = getServiceResources()[0];

        HOT_AssignOrReserveSAService.Input requestItem = createRequest(
            serviceAppointment.Id,
            firstResource.Id,
            'Scheduled'
        );

        Test.startTest();
        HOT_AssignOrReserveSAService.Result response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ requestItem }
        )[0];
        Test.stopTest();

        serviceAppointment = [
            SELECT Status, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        HOT_InterestedResource__c interestedResource = [
            SELECT Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id AND ServiceResource__c = :firstResource.Id
            LIMIT 1
        ];
        Integer assignedResourceCount = [
            SELECT COUNT()
            FROM AssignedResource
            WHERE ServiceAppointmentId = :serviceAppointment.Id
        ];

        System.assertEquals(true, response.success, 'Flow action should succeed');
        System.assertEquals('Tolken ble reservert til oppdraget.', response.message);
        System.assertEquals('Scheduled', serviceAppointment.Status, 'Service appointment should be scheduled');
        System.assertEquals(firstResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Resource should be set');
        System.assertEquals(
            firstResource.RelatedRecordId,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Assigned user should be set'
        );
        System.assertEquals('Reserved', interestedResource.Status__c, 'Interested resource should stay reserved');
        System.assertEquals(1, assignedResourceCount, 'Only one assigned resource should exist');
    }

    @IsTest
    static void assignDirectlyToDispatched_fromNone() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        ServiceResource firstResource = getServiceResources()[0];

        HOT_AssignOrReserveSAService.Input requestItem = createRequest(
            serviceAppointment.Id,
            firstResource.Id,
            'Dispatched'
        );

        Test.startTest();
        HOT_AssignOrReserveSAService.Result response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ requestItem }
        )[0];
        Test.stopTest();

        serviceAppointment = [
            SELECT Status, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        HOT_InterestedResource__c interestedResource = [
            SELECT Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id AND ServiceResource__c = :firstResource.Id
            LIMIT 1
        ];

        System.assertEquals(true, response.success, 'Flow action should succeed');
        System.assertEquals('Tolken ble tildelt oppdraget.', response.message);
        System.assertEquals('Dispatched', serviceAppointment.Status, 'Service appointment should be dispatched');
        System.assertEquals(firstResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Resource should be set');
        System.assertEquals(
            firstResource.RelatedRecordId,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Assigned user should be set'
        );
        System.assertEquals('Assigned', interestedResource.Status__c, 'Interested resource should be assigned');
    }

    @IsTest
    static void reserveFromReleasedToFreelance_createsInitialReservation() {
        ServiceAppointment serviceAppointment = createReleasedToFreelanceServiceAppointment();
        ServiceResource firstResource = getServiceResources()[0];

        HOT_AssignOrReserveSAService.Input requestItem = createRequest(
            serviceAppointment.Id,
            firstResource.Id,
            'Scheduled'
        );

        Test.startTest();
        HOT_AssignOrReserveSAService.Result response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ requestItem }
        )[0];
        Test.stopTest();

        serviceAppointment = [
            SELECT Status, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        Integer assignedResourceCount = [
            SELECT COUNT()
            FROM AssignedResource
            WHERE ServiceAppointmentId = :serviceAppointment.Id
        ];

        System.assertEquals(true, response.success, 'Released to Freelance status should allow first reservation');
        System.assertEquals('Tolken ble reservert til oppdraget.', response.message);
        System.assertEquals('Scheduled', serviceAppointment.Status, 'Service appointment should be scheduled');
        System.assertEquals(firstResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Resource should be set');
        System.assertEquals(
            firstResource.RelatedRecordId,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Assigned user should be set'
        );
        System.assertEquals(1, assignedResourceCount, 'Only one assigned resource should exist');
    }

    @IsTest
    static void rejectsWhenInterpreterAlreadyExists() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        List<ServiceResource> serviceResources = getServiceResources();
        ServiceResource firstResource = serviceResources[0];
        ServiceResource secondResource = serviceResources[1];

        update new ServiceAppointment(
            Id = serviceAppointment.Id,
            HOT_ServiceResource__c = firstResource.Id,
            HOT_AssignedResourceId__c = firstResource.RelatedRecordId
        );

        HOT_AssignOrReserveSAService.Input requestItem = createRequest(
            serviceAppointment.Id,
            secondResource.Id,
            'Scheduled'
        );

        Test.startTest();
        HOT_AssignOrReserveSAService.Result response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ requestItem }
        )[0];
        Test.stopTest();

        List<AssignedResource> assignedResources = [
            SELECT Id, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId = :serviceAppointment.Id
        ];

        System.assertEquals(false, response.success, 'Existing resource should block the action');
        System.assertEquals(
            'Dette oppdraget har allerede en valgt tolk. Endring av eksisterende reservering eller tildeling må gjøres i standardprosessen.',
            response.message
        );
        System.assertEquals(0, assignedResources.size(), 'No assigned resource should be created');
    }

    @IsTest
    static void rejectsWhenStatusIsNotNone() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        ServiceResource firstResource = getServiceResources()[0];

        update new ServiceAppointment(Id = serviceAppointment.Id, Status = 'Scheduled');

        HOT_AssignOrReserveSAService.Input requestItem = createRequest(
            serviceAppointment.Id,
            firstResource.Id,
            'Scheduled'
        );

        Test.startTest();
        HOT_AssignOrReserveSAService.Result response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ requestItem }
        )[0];
        Test.stopTest();

        Integer assignedResourceCount = [
            SELECT COUNT()
            FROM AssignedResource
            WHERE ServiceAppointmentId = :serviceAppointment.Id
        ];

        System.assertEquals(false, response.success, 'Unsupported source status should block the action');
        System.assertEquals(
            'Denne handlingen kan bare brukes når oppdraget har status Åpen eller Frigitt til frilanstolker. Nåværende status er Scheduled.',
            response.message
        );
        System.assertEquals(0, assignedResourceCount, 'No assigned resource should be created');
    }

    @IsTest
    static void serviceProviderReservesFromNone() {
        assertServiceProviderAssignment(getServiceAppointment(), 'Scheduled');
    }

    @IsTest
    static void serviceProviderAssignsFromNone() {
        assertServiceProviderAssignment(getServiceAppointment(), 'Dispatched');
    }

    @IsTest
    static void serviceProviderReservesFromReleased() {
        assertServiceProviderAssignment(createReleasedToFreelanceServiceAppointment(), 'Scheduled');
    }

    @IsTest
    static void serviceProviderAssignsFromReleased() {
        assertServiceProviderAssignment(createReleasedToFreelanceServiceAppointment(), 'Dispatched');
    }

    private static void assertServiceProviderAssignment(ServiceAppointment appointment, String targetStatus) {
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        ServiceResource resource = getServiceResources()[0];

        Test.startTest();
        HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, targetStatus) }
        )[0];
        Test.stopTest();

        ServiceAppointment actual = [
            SELECT Status, HOT_TjenesteleverandorStatus__c, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.isTrue(result.success, result.message);
        Assert.areEqual(targetStatus, actual.Status);
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c, 'Provider status must be preserved');
        Assert.areEqual(resource.Id, actual.HOT_ServiceResource__c);
        Assert.areEqual(resource.RelatedRecordId, actual.HOT_AssignedResourceId__c);
        Assert.areEqual(1, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsUnacceptedAppointment() {
        ServiceAppointment appointment = getServiceAppointment();
        ServiceResource resource = getServiceResources()[0];
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Transferred');

        Test.startTest();
        for (String targetStatus : new List<String>{ 'Scheduled', 'Dispatched' }) {
            HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
                new List<HOT_AssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, targetStatus) }
            )[0];
            Assert.isFalse(result.success);
            Assert.areEqual('Oppdraget må være akseptert av tjenesteleverandør.', result.message);
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsNonFreelanceAndInactiveResources() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        List<ServiceResource> resources = getServiceResources();
        resources[0].HOT_IsFreelanceInterpreter__c = false;
        resources[1].IsActive = false;
        update resources;

        Test.startTest();
        for (ServiceResource resource : resources) {
            HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
                new List<HOT_AssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, 'Dispatched') }
            )[0];
            Assert.isFalse(result.success);
            Assert.areEqual('Du må velge en aktiv tolk.', result.message);
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsRepeatedAssignmentInSameBatch() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        HOT_AssignOrReserveSAService.Input input = createRequest(
            appointment.Id,
            getServiceResources()[0].Id,
            'Scheduled'
        );

        Test.startTest();
        List<HOT_AssignOrReserveSAService.Result> results = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ input, input }
        );
        Test.stopTest();

        Assert.isTrue(results[0].success, results[0].message);
        Assert.isFalse(results[1].success, 'The same appointment cannot receive a second interpreter');
        Assert.areEqual(1, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderDispatchesReservedInterpreter() {
        ServiceAppointment appointment = getServiceAppointment();
        ServiceResource resource = getServiceResources()[0];
        reserveForServiceProvider(appointment.Id, resource.Id);
        AssignedResource reservation = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointment.Id
        ];

        Test.startTest();
        HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, 'Dispatched') }
        )[0];
        Test.stopTest();

        ServiceAppointment actual = [
            SELECT Status, HOT_TjenesteleverandorStatus__c, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.isTrue(result.success, result.message);
        Assert.areEqual('Dispatched', actual.Status);
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c);
        Assert.areEqual(resource.Id, actual.HOT_ServiceResource__c);
        Assert.areEqual(resource.RelatedRecordId, actual.HOT_AssignedResourceId__c);
        List<AssignedResource> assignments = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointment.Id
        ];
        Assert.areEqual(1, assignments.size(), 'Dispatch must reuse the existing reservation');
        Assert.areEqual(reservation.Id, assignments[0].Id);
    }

    @IsTest
    static void serviceProviderRejectsChangedReservedInterpreter() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        reserveForServiceProvider(appointment.Id, resources[0].Id);

        Test.startTest();
        HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ createRequest(appointment.Id, resources[1].Id, 'Dispatched') }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual(
            'Den reserverte tolken finnes ikke eller er endret. Last inn oppdraget på nytt.',
            result.message
        );
        Assert.areEqual('Scheduled', [SELECT Status FROM ServiceAppointment WHERE Id = :appointment.Id].Status);
        Assert.areEqual(
            resources[0].Id,
            [SELECT ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]
            .ServiceResourceId
        );
    }

    @IsTest
    static void serviceProviderRejectsDispatchWithoutReservation() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(
            Id = appointment.Id,
            Status = 'Scheduled',
            HOT_TjenesteleverandorStatus__c = 'Accepted'
        );

        Test.startTest();
        HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{
                createRequest(appointment.Id, getServiceResources()[0].Id, 'Dispatched')
            }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual('Scheduled', [SELECT Status FROM ServiceAppointment WHERE Id = :appointment.Id].Status);
        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    private static void reserveForServiceProvider(Id appointmentId, Id resourceId) {
        update new ServiceAppointment(Id = appointmentId, HOT_TjenesteleverandorStatus__c = 'Accepted');
        HOT_AssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Input>{ createRequest(appointmentId, resourceId, 'Scheduled') }
        )[0];
        Assert.isTrue(result.success, result.message);
    }

    private static HOT_AssignOrReserveSAService.Input createRequest(
        Id serviceAppointmentId,
        Id serviceResourceId,
        String targetStatus
    ) {
        HOT_AssignOrReserveSAService.Input requestItem = new HOT_AssignOrReserveSAService.Input();
        requestItem.serviceAppointmentId = serviceAppointmentId;
        requestItem.serviceResourceId = serviceResourceId;
        requestItem.targetStatus = targetStatus;
        return requestItem;
    }

    private static ServiceAppointment getServiceAppointment() {
        return [SELECT Id, Status FROM ServiceAppointment WHERE Subject = 'AssignOrReserve' LIMIT 1];
    }

    private static List<ServiceResource> getServiceResources() {
        return [SELECT Id, RelatedRecordId FROM ServiceResource ORDER BY Name ASC];
    }

    private static ServiceAppointment createReleasedToFreelanceServiceAppointment() {
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id
            FROM WorkOrderLineItem
            WHERE WorkOrder.HOT_Request__r.Subject__c = 'AssignOrReserve'
            LIMIT 1
        ];
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];

        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.Subject = 'ReleasedAssignOrReserve';
        serviceAppointment.Status = 'Released to Freelance';
        serviceAppointment.ServiceTerritoryId = serviceTerritory.Id;
        serviceAppointment.HOT_IsReleasedToFreelance__c = true;
        serviceAppointment.HOT_FreelanceSubject__c = 'Test release';
        serviceAppointment.HOT_DeadlineDate__c = Date.today();
        insert serviceAppointment;

        return serviceAppointment;
    }
}
