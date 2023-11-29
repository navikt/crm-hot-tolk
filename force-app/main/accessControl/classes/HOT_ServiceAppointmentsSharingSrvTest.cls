@IsTest
private class HOT_ServiceAppointmentsSharingSrvTest {
    @TestSetup
    static void makeData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;
    }

    @IsTest
    private static void testGrantAccess() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_1.HOT_Request__c = request.Id;
        insert serviceAppointment_1;
        ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_2.HOT_Request__c = request.Id;
        insert serviceAppointment_2;

        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];

        Map<Id, Id> serviceAppointmentsMap = new Map<Id, Id>();
        serviceAppointmentsMap.put('a0C2o00001WJvIHEA1', serviceAppointment_1.Id);
        serviceAppointmentsMap.put('a0C2o00001WJvIHEA2', serviceAppointment_2.Id);

        Map<Id, Id> resourceMap = new Map<Id, Id>();
        resourceMap.put('a0C2o00001WJvIHEA1', serviceResources[0].Id);
        resourceMap.put('a0C2o00001WJvIHEA2', serviceResources[0].Id);
        Test.startTest();
        HOT_ServiceAppointmentsSharingService.grantAccess(serviceAppointmentsMap, resourceMap);
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :serviceAppointment_1.Id
                    AND RowCause = 'Manual'
            ]
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :serviceAppointment_2.Id
                    AND RowCause = 'Manual'
            ]
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM WorkOrderShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :workOrder.Id
                    AND RowCause = 'Manual'
            ]
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM AccountShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND AccountId = :account.Id
                    AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testRemoveAccessForSpecificUsers() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_1.HOT_Request__c = request.Id;
        insert serviceAppointment_1;
        ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_2.HOT_Request__c = request.Id;
        insert serviceAppointment_2;
        ServiceAppointment serviceAppointment_3 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_3.HOT_Request__c = request.Id;
        insert serviceAppointment_3;

        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
        Set<Id> userIds = new Set<Id>();

        List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
        shares.add(
            new ServiceAppointmentShare(
                ParentId = serviceAppointment_1.Id,
                AccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = serviceResources[0].RelatedRecordId
            )
        );
        shares.add(
            new ServiceAppointmentShare(
                ParentId = serviceAppointment_2.Id,
                AccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = serviceResources[0].RelatedRecordId
            )
        );
        shares.add(
            new ServiceAppointmentShare(
                ParentId = serviceAppointment_3.Id,
                AccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = serviceResources[0].RelatedRecordId
            )
        );
        insert shares;
        System.assertEquals(3, [SELECT COUNT() FROM ServiceAppointmentShare WHERE RowCause = 'Manual']);

        Map<Id, Id> serviceAppointmentsMap = new Map<Id, Id>();
        serviceAppointmentsMap.put('a0C2o00001WJvIHEA1', serviceAppointment_1.Id);
        serviceAppointmentsMap.put('a0C2o00001WJvIHEA2', serviceAppointment_2.Id);

        Map<Id, Id> usersMap = new Map<Id, Id>();
        usersMap.put('a0C2o00001WJvIHEA1', serviceResources[0].Id);
        usersMap.put('a0C2o00001WJvIHEA2', serviceResources[0].Id);
        Test.startTest();
        HOT_ServiceAppointmentsSharingService.removeAccessForSpecificUsers(serviceAppointmentsMap, usersMap);
        Test.stopTest();
        //two manual shares should be deleted. One left
        System.assertEquals(1, [SELECT COUNT() FROM ServiceAppointmentShare WHERE RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM ServiceAppointmentShare WHERE RowCause = 'Manual']);
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :serviceAppointment_3.Id
                    AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testRemoveManualAccess() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_1.HOT_Request__c = request.Id;
        insert serviceAppointment_1;
        ServiceAppointment serviceAppointment_2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_2.HOT_Request__c = request.Id;
        insert serviceAppointment_2;

        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
        Set<Id> userIds = new Set<Id>();
        for (ServiceResource sr : serviceResources) {
            userIds.add(sr.RelatedRecordId);
        }

        List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
        shares.add(
            new ServiceAppointmentShare(
                ParentId = serviceAppointment_1.Id,
                AccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = serviceResources[0].RelatedRecordId
            )
        );
        shares.add(
            new ServiceAppointmentShare(
                ParentId = serviceAppointment_2.Id,
                AccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = serviceResources[0].RelatedRecordId
            )
        );
        insert shares;

        Set<Id> serviceAppointIds = new Set<Id>{ serviceAppointment_1.Id };
        Test.startTest();
        HOT_ServiceAppointmentsSharingService.removeManualAccess(serviceAppointIds);
        Test.stopTest();
        //one manual share should be deleted. One left
        System.assertEquals(1, [SELECT COUNT() FROM ServiceAppointmentShare WHERE RowCause = 'Manual']);
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :serviceAppointment_2.Id
                    AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testKeepAccessOnSAOwnerChange() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.HOT_Request__c = request.Id;
        insert serviceAppointment;

        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];

        AssignedResource assignedResource = new AssignedResource(
            ServiceAppointmentId = serviceAppointment.Id,
            ServiceResourceId = serviceResources[0].Id
        );
        insert assignedResource;

        Test.startTest();
        serviceAppointment.OwnerId = UserInfo.getUserId();
        update serviceAppointment;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :serviceAppointment.Id
                    AND RowCause = 'Manual'
            ]
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM WorkOrderShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND ParentId = :workOrder.Id
                    AND RowCause = 'Manual'
            ]
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM AccountShare
                WHERE
                    UserOrGroupId = :serviceResources[0].RelatedRecordId
                    AND AccountId = :account.Id
                    AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testRecalculateManualSharing() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.HOT_Request__c = request.Id;
        insert serviceAppointment;

        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];

        AssignedResource assignedResource = new AssignedResource(
            ServiceAppointmentId = serviceAppointment.Id,
            ServiceResourceId = serviceResources[0].Id
        );
        insert assignedResource;

        serviceAppointment = [
            SELECT Id, HOT_IsRecalculateManualSharing__c, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        serviceAppointment.HOT_IsRecalculateManualSharing__c = true;
        serviceAppointment.HOT_ServiceResource__c = null;
        serviceAppointment.Status = 'Dispatched';
        Test.startTest();
        update serviceAppointment;

        serviceAppointment = [
            SELECT
                Id,
                HOT_IsRecalculateManualSharing__c,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.RelatedRecordId,
                HOT_DelPol_IsHideRecord__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        List<ServiceAppointmentShare> serviceAppointmentShares = [
            SELECT Id
            FROM ServiceAppointmentShare
            WHERE ParentId = :serviceAppointment.Id AND RowCause = 'Manual'
        ];

        Test.stopTest();
        System.assertEquals(
            true,
            serviceAppointment.HOT_IsRecalculateManualSharing__c,
            'Could not set flag on service appointment'
        );
        System.assertEquals(1, serviceAppointmentShares.size(), 'Could not create service appointment share');

        HOT_ServiceAppointmentsSharingService.recalculateManualSharing(
            new List<ServiceAppointment>{ serviceAppointment }
        );

        serviceAppointmentShares = [
            SELECT Id
            FROM ServiceAppointmentShare
            WHERE ParentId = :serviceAppointment.Id AND RowCause = 'Manual'
        ];
        serviceAppointment = [
            SELECT Id, HOT_IsRecalculateManualSharing__c, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(0, serviceAppointmentShares.size(), 'Could not delete service appointment share');
        System.assertEquals(
            false,
            serviceAppointment.HOT_IsRecalculateManualSharing__c,
            'Could not reset flag on service appointment'
        );
    }
}
