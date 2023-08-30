@IsTest
private class HOT_AssignedResourceAccessHandlerTest {
    @IsTest
    private static void testAssignedResourceHasAccessToServiceAppointmentAfterInsertScheduled() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointmentId,
            serviceResourceId
        );
        insert assignedResource;

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :userId AND ParentId = :serviceAppointmentId AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testAssignedResourceHasAccessToServiceAppointmentAfterInsertDispatched() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResourceId);
        insert assignedResource;

        sa.Status = 'Dispatched';
        update sa;

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :userId AND ParentId = :sa.Id AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testSharingRecalculationFlagWhenAssignedResourceIsDeleted() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        Id serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        Id userId = [SELECT RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResourceId);
        insert assignedResource;

        sa.Status = 'Dispatched';
        update sa;

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :userId AND ParentId = :sa.Id AND RowCause = 'Manual'
            ]
        );

        Test.startTest();
        delete assignedResource;
        Test.stopTest();

        ServiceAppointment serviceAppointment = [
            SELECT HOT_IsRecalculateManualSharing__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];
        System.assertEquals(true, serviceAppointment.HOT_IsRecalculateManualSharing__c);
    }

    @IsTest
    private static void testWhenAssignedResourceIsChangedBeforeDispatched() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
        Id serviceResourceId1 = serviceResources[0].Id;
        Id userId1 = serviceResources[0].RelatedRecordId;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResourceId1);
        insert assignedResource;

        Id serviceResourceId2 = serviceResources[1].Id;
        Id userId2 = serviceResources[1].RelatedRecordId;

        Test.startTest();
        assignedResource.ServiceResourceId = serviceResourceId2;
        update assignedResource;
        Test.stopTest();

        ServiceAppointment serviceAppointment = [
            SELECT HOT_IsRecalculateManualSharing__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];
        System.assertEquals(false, serviceAppointment.HOT_IsRecalculateManualSharing__c);

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    (UserOrGroupId = :userId1
                    OR UserOrGroupId = :userId2)
                    AND ParentId = :sa.Id
                    AND RowCause = 'Manual'
            ]
        );
    }

    @IsTest
    private static void testWhenAssignedResourceIsChangedAfterDispatched() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;
        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];
        Id serviceResourceId1 = serviceResources[0].Id;
        Id userId1 = serviceResources[0].RelatedRecordId;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResourceId1);
        insert assignedResource;

        sa.Status = 'Dispatched';
        update sa;

        Id serviceResourceId2 = serviceResources[1].Id;
        Id userId2 = serviceResources[1].RelatedRecordId;

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :userId1 AND ParentId = :sa.Id AND RowCause = 'Manual'
            ]
        );

        Test.startTest();
        assignedResource.ServiceResourceId = serviceResourceId2;
        update assignedResource;
        Test.stopTest();

        ServiceAppointment serviceAppointment = [
            SELECT HOT_IsRecalculateManualSharing__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];
        System.assertEquals(true, serviceAppointment.HOT_IsRecalculateManualSharing__c);

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :userId2 AND ParentId = :sa.Id AND RowCause = 'Manual'
            ]
        );
    }
}
