@IsTest
private class HOT_WorkOrderLineItemHandlerTest {
    @IsTest
    private static void testCreateChildRecords() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        HOT_Resource__c resource1 = HOT_TestDataFactory.createResource(serviceResource);
        insert resource1;
        HOT_Resource__c resource2 = HOT_TestDataFactory.createResource(serviceResource);
        insert resource2;
        HOT_Resource__c resource3 = HOT_TestDataFactory.createResource(serviceResource);
        insert resource3;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.ServiceTerritory__c = serviceTerritory.Id;
        request.Description__c = 'Description';
        request.InterpretationStreet__c = 'Street 1';
        request.InterpretationPostalCode__c = '1111';
        request.InterpretationPostalCity__c = 'City 1';
        request.MeetingStreet__c = 'Street 2';
        request.MeetingPostalCode__c = '2222';
        request.MeetingPostalCity__c = 'City 2';
        request.NumberOfInterpreters__c = 5;
        request.PreferredResource1__c = resource1.Id;
        request.PreferredResource2__c = resource2.Id;
        request.PreferredResource3__c = resource3.Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        workOrderLineItem.HOT_NumberOfInterpreters__c = 5;

        Test.startTest();
        insert workOrderLineItem;
        Test.stopTest();

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, Subject, ServiceTerritoryId, Status
            FROM ServiceAppointment
            WHERE ParentRecordId = :workOrderLineItem.Id
        ];

        System.assertEquals(5, serviceAppointments.size(), 'Could not create ServiceAppointments');
        System.assertEquals(
            serviceTerritory.Id,
            serviceAppointments[0].ServiceTerritoryId,
            'Could not set ServiceTerritoryId'
        );
        System.assertEquals('None', serviceAppointments[0].Status, 'Could not set default Status');
    }

    @IsTest
    private static void testSetDefaultFields() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Description__c = 'Description';
        request.InterpretationStreet__c = 'Street 1';
        request.InterpretationPostalCode__c = '1111';
        request.InterpretationPostalCity__c = 'City 1';
        request.MeetingStreet__c = 'Street 2';
        request.MeetingPostalCode__c = '2222';
        request.MeetingPostalCity__c = 'City 2';
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.Street = 'Street 2';
        workOrder.PostalCode = '2222';
        workOrder.City = 'City 2';
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        workOrderLineItem.Status = 'Canceled';
        workOrderLineItem.StartDate = null;
        workOrderLineItem.EndDate = null;
        workOrderLineItem.Street = '';
        workOrderLineItem.PostalCode = '';
        workOrderLineItem.City = '';

        Test.startTest();
        insert workOrderLineItem;
        Test.stopTest();

        workOrderLineItem = [
            SELECT Id, Subject, Status, Description, Street, HOT_InterpretationPostalStreet__c
            FROM WorkOrderLineItem
            WHERE Id = :workOrderLineItem.Id
        ];

        System.assertEquals(request.Subject__c, workOrderLineItem.Subject, 'Could not set Subject');
        System.assertEquals(request.Description__c, workOrderLineItem.Description, 'Could not set Description');
        System.assertEquals(request.MeetingStreet__c, workOrderLineItem.Street, 'Could not set Street');
        System.assertEquals(
            request.InterpretationStreet__c,
            workOrderLineItem.HOT_InterpretationPostalStreet__c,
            'Could not set HOT_InterpretationPostalStreet__c'
        );
        System.assertEquals('New', workOrderLineItem.Status, 'Could not set default Status');
    }
}
