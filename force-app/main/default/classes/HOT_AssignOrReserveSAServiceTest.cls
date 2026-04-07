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
    static void assignDirectlyToDispatched_fromNone() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        ServiceResource firstResource = getServiceResources()[0];

        HOT_AssignOrReserveSAService.Request requestItem = new HOT_AssignOrReserveSAService.Request();
        requestItem.serviceAppointmentId = serviceAppointment.Id;
        requestItem.serviceResourceId = firstResource.Id;
        requestItem.targetStatus = 'Dispatched';

        Test.startTest();
        HOT_AssignOrReserveSAService.Response response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Request>{ requestItem }
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
        System.assertEquals('Dispatched', serviceAppointment.Status, 'Service appointment should be dispatched');
        System.assertEquals(firstResource.Id, serviceAppointment.HOT_ServiceResource__c, 'Resource should be set');
        System.assertEquals(
            firstResource.RelatedRecordId,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Assigned user should be set'
        );
        System.assertEquals('Assigned', interestedResource.Status__c, 'Interested resource should be assigned');
        System.assertEquals(1, assignedResourceCount, 'Only one assigned resource should exist');
    }

    @IsTest
    static void reserveExistingDispatchedResource_setsInterestedResourceBackToReserved() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        ServiceResource firstResource = getServiceResources()[0];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, firstResource.Id);
        insert assignedResource;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        HOT_AssignOrReserveSAService.Request requestItem = new HOT_AssignOrReserveSAService.Request();
        requestItem.serviceAppointmentId = serviceAppointment.Id;
        requestItem.serviceResourceId = firstResource.Id;
        requestItem.targetStatus = 'Scheduled';

        Test.startTest();
        HOT_AssignOrReserveSAService.Response response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Request>{ requestItem }
        )[0];
        Test.stopTest();

        serviceAppointment = [
            SELECT Status
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
        System.assertEquals('Scheduled', serviceAppointment.Status, 'Service appointment should be scheduled');
        System.assertEquals('Reserved', interestedResource.Status__c, 'Interested resource should be reserved again');
    }

    @IsTest
    static void changeResourceAndKeepScheduled_updatesInterestedResources() {
        ServiceAppointment serviceAppointment = getServiceAppointment();
        List<ServiceResource> serviceResources = getServiceResources();
        ServiceResource firstResource = serviceResources[0];
        ServiceResource secondResource = serviceResources[1];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, firstResource.Id);
        insert assignedResource;

        serviceAppointment.Status = 'Scheduled';
        update serviceAppointment;

        HOT_AssignOrReserveSAService.Request requestItem = new HOT_AssignOrReserveSAService.Request();
        requestItem.serviceAppointmentId = serviceAppointment.Id;
        requestItem.serviceResourceId = secondResource.Id;
        requestItem.targetStatus = 'Scheduled';

        Test.startTest();
        HOT_AssignOrReserveSAService.Response response = HOT_AssignOrReserveSAService.assignOrReserve(
            new List<HOT_AssignOrReserveSAService.Request>{ requestItem }
        )[0];
        Test.stopTest();

        AssignedResource updatedAssignedResource = [
            SELECT ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId = :serviceAppointment.Id
            LIMIT 1
        ];
        Map<Id, HOT_InterestedResource__c> interestedResourcesByServiceResource = new Map<Id, HOT_InterestedResource__c>();
        for (
            HOT_InterestedResource__c interestedResource : [
                SELECT ServiceResource__c, Status__c
                FROM HOT_InterestedResource__c
                WHERE ServiceAppointment__c = :serviceAppointment.Id
            ]
        ) {
            interestedResourcesByServiceResource.put(interestedResource.ServiceResource__c, interestedResource);
        }

        System.assertEquals(true, response.success, 'Flow action should succeed');
        System.assertEquals(
            secondResource.Id,
            updatedAssignedResource.ServiceResourceId,
            'Assigned resource should be updated'
        );
        System.assertEquals(
            'Reserved',
            interestedResourcesByServiceResource.get(secondResource.Id).Status__c,
            'New interpreter should be reserved'
        );
        System.assertEquals(
            'Not Assigned',
            interestedResourcesByServiceResource.get(firstResource.Id).Status__c,
            'Previous interpreter should no longer be assigned'
        );
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
