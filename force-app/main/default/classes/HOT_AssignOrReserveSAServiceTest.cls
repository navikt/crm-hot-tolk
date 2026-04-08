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

        WorkOrder workOrder = [
            SELECT Id
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];
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
    static void rejectsWhenInterpreterAlreadyExists() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        List<ServiceResource> serviceResources = getServiceResources();
        ServiceResource firstResource = serviceResources[0];
        ServiceResource secondResource = serviceResources[1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, firstResource.Id);
        insert assignedResource;

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
        System.assertEquals(1, assignedResources.size(), 'No new assigned resource should be created');
        System.assertEquals(firstResource.Id, assignedResources[0].ServiceResourceId, 'Original resource should remain');
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

        System.assertEquals(false, response.success, 'Non-None status should block the action');
        System.assertEquals(
            'Denne handlingen kan bare brukes når oppdraget har status None. Nåværende status er Scheduled.',
            response.message
        );
        System.assertEquals(0, assignedResourceCount, 'No assigned resource should be created');
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
        return [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Subject = 'AssignOrReserve'
            LIMIT 1
        ];
    }

    private static List<ServiceResource> getServiceResources() {
        return [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            ORDER BY Name ASC
        ];
    }
}
