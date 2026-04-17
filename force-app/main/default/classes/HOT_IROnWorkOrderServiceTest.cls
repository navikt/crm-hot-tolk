@IsTest
private class HOT_IROnWorkOrderServiceTest {
    @TestSetup
    static void makeData() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('woserv', profile);
        insert user;

        Account accountRecord = HOT_TestDataFactory.createAccount(false);
        insert accountRecord;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        serviceResource.AccountId = accountRecord.Id;
        serviceResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert serviceResource;

        insert HOT_TestDataFactory.createServiceTerritoryMember(serviceResource, serviceTerritory);

        HOT_Resource__c resource = new HOT_Resource__c(Name = 'WO Service Resource', Service_Resource__c = serviceResource.Id);
        insert resource;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('WO SERVICE TEST', workType);
        request.PreferredResource1__c = resource.Id;
        insert request;
        request.Status__c = 'Godkjent';
        update request;
    }

    private static ServiceAppointment createServiceAppointmentOnWorkOrder(Id workOrderId, Id workTypeId, String subject) {
        Datetime startTime = Datetime.now().addHours(6);
        WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem(
            WorkOrderId = workOrderId,
            Status = 'New',
            Subject = subject,
            HOT_NumberOfInterpreters__c = 1,
            StartDate = startTime,
            EndDate = startTime.addHours(2),
            WorkTypeId = workTypeId
        );
        insert workOrderLineItem;

        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.Subject = subject;
        insert serviceAppointment;

        return [
            SELECT Id, HOT_ServiceResource__c, HOT_WorkOrderID__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
    }

    @IsTest
    static void getInterestedResourcesToUpdateOnDispatchReturnsSameWorkOrderInterestedResources() {
        ServiceAppointment primaryServiceAppointment = [
            SELECT Id, HOT_WorkOrderID__c, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_WorkOrderLineItem__r.WorkTypeId
            FROM ServiceAppointment
            WHERE Subject = 'WO SERVICE TEST'
            LIMIT 1
        ];
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment sameWorkOrderServiceAppointment = createServiceAppointmentOnWorkOrder(
            primaryServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId,
            primaryServiceAppointment.HOT_WorkOrderLineItem__r.WorkTypeId,
            'WO SERVICE SAME WO'
        );

        HOT_InterestedResource__c sameWorkOrderInterestedResource = HOT_TestDataFactory.createInterestedResource(
            sameWorkOrderServiceAppointment.Id,
            serviceResource.Id
        );
        sameWorkOrderInterestedResource.Status__c = 'Interested';
        insert sameWorkOrderInterestedResource;

        primaryServiceAppointment = [
            SELECT Id, HOT_WorkOrderID__c
            FROM ServiceAppointment
            WHERE Id = :primaryServiceAppointment.Id
        ];
        primaryServiceAppointment.HOT_ServiceResource__c = serviceResource.Id;

        List<HOT_InterestedResource__c> interestedResourcesToUpdate = HOT_InterestedResourceOnWorkOrderService.getInterestedResourcesToUpdateOnDispatch(
            new List<ServiceAppointment>{ primaryServiceAppointment }
        );

        System.assertEquals(1, interestedResourcesToUpdate.size(), 'Expected one related IR on same Work Order');
        System.assertEquals(
            sameWorkOrderInterestedResource.Id,
            interestedResourcesToUpdate[0].Id,
            'Expected related IR to be returned'
        );
        System.assertEquals('Not Assigned', interestedResourcesToUpdate[0].Status__c, 'Expected status to be updated');
    }
}
