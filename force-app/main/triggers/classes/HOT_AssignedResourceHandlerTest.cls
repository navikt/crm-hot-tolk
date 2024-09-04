@IsTest
private class HOT_AssignedResourceHandlerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('subject 2', workType);
        requests.add(request);
        requests.add(request2);
        insert requests;

        request.Status__c = 'Godkjent';
        request2.Status__c = 'Godkjent';
        update requests;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user = HOT_TestDataFactory.createUser('User2', profile);
        insert user;

        List<ServiceResource> serviceResources = new List<ServiceResource>();
        ServiceResource serviceResourceAdmin = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        serviceResourceAdmin.HOT_IsFreelanceInterpreter__c = true;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        serviceResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        serviceResources.add(serviceResourceAdmin);
        serviceResources.add(serviceResource);
        insert serviceResources;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert interestedResource;
    }

    @IsTest
    static void createUpdateDeleteAssignedResourceTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource testResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId != :UserInfo.getUserId()
        ];
        ServiceResource adminResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];

        Test.startTest();

        //Testing onAfterInsert()
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            adminResource.Id
        );
        insert assignedResource;
        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals(
            adminResource.Id,
            serviceAppointment.HOT_ServiceResource__c,
            'Could not set HOT_ServiceResource__c onAfterInsert'
        );
        System.assertEquals(
            adminResource.RelatedRecordId,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Could not set HOT_AssignedResourceId__c onAfterInsert'
        );

        //Testing onAfterUpdate()
        assignedResource.ServiceResourceId = testResource.Id;
        update assignedResource;
        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals(
            testResource.Id,
            serviceAppointment.HOT_ServiceResource__c,
            'Could not set HOT_ServiceResource__c onAfterUpdate'
        );
        System.assertEquals(
            testResource.RelatedRecordId,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Could not set HOT_AssignedResourceId__c onAfterUpdate'
        );

        //Testing updates on InterestedResources
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, ServiceResource__c, Status__c
            FROM HOT_InterestedResource__c
        ];
        System.assertEquals(2, interestedResources.size(), 'Could not create interested resources correctly');
        Map<Id, HOT_InterestedResource__c> irBySR = new Map<Id, HOT_InterestedResource__c>();
        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            irBySR.put(interestedResource.ServiceResource__c, interestedResource);
        }
        System.assertEquals(
            'Reserved',
            irBySR.get(testResource.Id).Status__c,
            'Could not set correct status on InterestedResources'
        );
        System.assertEquals(
            'Withdrawn',
            irBySR.get(adminResource.Id).Status__c,
            'Could not set correct status on InterestedResources'
        );

        //Testing onAfterdelete()
        delete assignedResource;
        Test.stopTest();

        serviceAppointment = [
            SELECT
                Id,
                HOT_ServiceResource__c,
                HOT_AssignedResourceId__c,
                EarliestStartTime,
                DueDate,
                SchedStartTime,
                SchedEndTime,
                HOT_IsEmployedInterpreter__c,
                HOT_IsReleasedToFreelance__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals(
            null,
            serviceAppointment.HOT_ServiceResource__c,
            'Could not set HOT_ServiceResource__c onAfterdelete'
        );
        System.assertEquals(
            null,
            serviceAppointment.HOT_AssignedResourceId__c,
            'Could not set HOT_AssignedResourceId__c onAfterdelete'
        );
        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.EarliestStartTime,
            'Could not set EarliestStartTime onAfterdelete'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.DueDate,
            'Could not set SchedEndTime onAfterdelete'
        );
        System.assertEquals(
            true,
            serviceAppointment.HOT_IsEmployedInterpreter__c,
            'Could not set HOT_IsEmployedInterpreter__c onAfterdelete'
        );
        System.assertEquals(
            false,
            serviceAppointment.HOT_IsReleasedToFreelance__c,
            'Could not set HOT_IsReleasedToFreelance__c onAfterdelete'
        );
        List<HOT_InterestedResource__c> interestedResourcesAfterDelete = [
            SELECT Id, ServiceResource__c, Status__c
            FROM HOT_InterestedResource__c
        ];
        Map<Id, HOT_InterestedResource__c> interestedResourcesNewStatuses = new Map<Id, HOT_InterestedResource__c>();
        for (HOT_InterestedResource__c interestedResource : interestedResourcesAfterDelete) {
            interestedResourcesNewStatuses.put(interestedResource.ServiceResource__c, interestedResource);
        }

        System.assertEquals(
            'Withdrawn',
            interestedResourcesNewStatuses.get(testResource.Id).Status__c,
            'Status was supposed to be changed'
        );
    }

    @IsTest
    static void createInterestedResourcesTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource testResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId != :UserInfo.getUserId()
        ];
        testResource.HOT_IsFreelanceInterpreter__c = true;
        update testResource;
        //update adminResource;
        ServiceAppointment serviceAppointment2 = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Subject = 'subject 2'
            LIMIT 1
        ];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            testResource.Id
        );
        insert assignedResource;
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
        ];
        System.assertEquals(1, interestedResources.size(), 'Interested Resource was not created.');

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment2.Id,
            testResource.Id
        );
        insert interestedResource;
        interestedResources = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment2.Id
        ];

        System.assertEquals(1, interestedResources.size(), 'Interested Resource should not have been created.');

        assignedResource.ServiceResourceId = testResource.Id;
        update assignedResource;
        interestedResources = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment2.Id
        ];
        System.assertEquals(1, interestedResources.size(), 'Interested Resource should not have been created.');
    }

    @IsTest
    static void throwExceptionIfSAHasOverlapOnARInsertTrueTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        ServiceAppointment serviceAppointment2 = [
            SELECT Id, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE Subject = 'subject 2'
            LIMIT 1
        ];

        ServiceResource adminResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

        Test.startTest();
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            adminResource.Id
        );
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            adminResource.Id
        );
        insert assignedResource;
        try {
            insert assignedResource2;
        } catch (Exception e) {
            Boolean expectedExceptionThrown = e.getMessage()
                .contains('Ressursen har allerede et oppdrag i dette tidsrommet');
            System.assertEquals(
                expectedExceptionThrown,
                true,
                'Assigned Resource should not have been inserted on new SA.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void throwExceptionIfSAHasOverlapOnARWhenARAlreadyExistsTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
        ServiceResource adminResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];
        User user2 = [SELECT Id FROM User WHERE Name = 'User2'];
        ServiceResource resource2 = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :user2.Id];

        Test.startTest();
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            adminResource.Id
        );

        // Add new AR to same SA
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource2.Id
        );
        insert assignedResource;
        try {
            insert assignedResource2;
        } catch (Exception e) {
            Boolean expectedExceptionThrown = e.getMessage()
                .contains('Du kan ikke sette opp flere ressurser på et oppdrag.');
            System.assertEquals(expectedExceptionThrown, true, 'Assigned Resource should not have been inserted.');
        }
        Test.stopTest();
    }

    @IsTest
    static void throwExceptionIfSAHasOverlapOnAREditFalseTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];

        ServiceAppointment serviceAppointment2 = [
            SELECT Id
            FROM ServiceAppointment
            WHERE Subject = 'subject 2'
            LIMIT 1
        ];

        ServiceResource adminResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];
        User user2 = [SELECT Id FROM User WHERE Name = 'User2'];
        ServiceResource resource2 = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :user2.Id];

        Test.startTest();
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            adminResource.Id
        );

        insert assignedResource;
        try {
            assignedResource.ServiceResourceId = resource2.Id;
            update assignedResource;
        } catch (Exception e) {
            Boolean expectedExceptionThrown = e.getMessage()
                .contains('Ressursen har allerede et oppdrag i dette tidsrommet');
            System.assertEquals(
                expectedExceptionThrown,
                false,
                'Service Resource on Assigned Resource should have been updated.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void throwExceptionIfSAHasOverlapOnAREditTrueTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];

        ServiceAppointment serviceAppointment2 = [
            SELECT Id
            FROM ServiceAppointment
            WHERE Subject = 'subject 2'
            LIMIT 1
        ];

        ServiceResource adminResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];
        User user2 = [SELECT Id FROM User WHERE Name = 'User2'];
        ServiceResource resource2 = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :user2.Id];

        Test.startTest();
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            adminResource.Id
        );

        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            resource2.Id
        );

        insert assignedResource;
        try {
            assignedResource.ServiceResourceId = resource2.Id;
            update assignedResource;
        } catch (Exception e) {
            Boolean expectedExceptionThrown = e.getMessage()
                .contains('Ressursen har allerede et oppdrag i dette tidsrommet');
            System.assertEquals(
                expectedExceptionThrown,
                true,
                'Service Resource on Assigned Resource should not have been updated.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void updateInterestedResourceStatusTest() {
        Hot_interestedresource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c
            FROM Hot_interestedresource__c
        ];
        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceAppointmentId = interestedResource.ServiceAppointment__c;
        assignedResource.ServiceResourceId = interestedResource.ServiceResource__c;
        insert assignedResource;

        interestedResource = [SELECT Id, Status__c FROM Hot_interestedresource__c];

        System.assertEquals(
            'Reserved',
            interestedResource.Status__c,
            'Could not set Interested Resource Status to Assigned'
        );
    }
    @IsTest
    static void moveExistingThreadBackToIRWhenARIsDeletedTest() {
        Hot_interestedresource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c, ServiceResource__r.AccountId
            FROM Hot_interestedresource__c
        ];
        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceAppointmentId = interestedResource.ServiceAppointment__c;
        assignedResource.ServiceResourceId = interestedResource.ServiceResource__c;
        insert assignedResource;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Account__c = interestedResource.ServiceResource__r.AccountId;
        thread.CRM_Related_Object__c = assignedResource.ServiceAppointmentId;
        thread.HOT_ServiceAppointment__c = assignedResource.ServiceAppointmentId;
        thread.HOT_IsEmployeeThread__c = false;
        insert thread;

        Test.startTest();
        delete assignedResource;

        List<Thread__c> checkThread = [
            SELECT Id, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id
        ];
        Test.stopTest();
        System.assertEquals(1, checkThread.size(), 'The thread was not moved back from SA to IR.');
    }
    @IsTest
    static void updateInterestedResourceStatusKeepDeclinedTest() {
        Hot_interestedresource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c
            FROM Hot_interestedresource__c
        ];
        interestedResource.Status__c = 'Declined';
        update interestedResource;

        interestedResource = [SELECT Id, Status__c, ServiceAppointment__c FROM Hot_interestedresource__c];

        ServiceAppointment sa = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Id = :interestedResource.ServiceAppointment__c
        ];
        sa.Status = 'Released to Freelance';
        update sa;

        System.assertEquals(
            'Declined',
            interestedResource.Status__c,
            'Should have kept their original status when released to freelance'
        );
    }
    @IsTest
    static void updateInterestedResourceStatusKeepCanceledTest() {
        Hot_interestedresource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c
            FROM Hot_interestedresource__c
        ];
        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceAppointmentId = interestedResource.ServiceAppointment__c;
        assignedResource.ServiceResourceId = interestedResource.ServiceResource__c;
        insert assignedResource;

        interestedResource = [SELECT Id, Status__c, ServiceAppointment__c FROM Hot_interestedresource__c];
        interestedResource.Status__c = 'Canceled by Interpreter';

        ServiceAppointment sa = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Id = :interestedResource.ServiceAppointment__c
        ];
        sa.Status = 'None';
        update sa;
        sa.Status = 'Released to Freelance';
        update sa;

        System.assertEquals(
            'Canceled by Interpreter',
            interestedResource.Status__c,
            'Should have kept their original status when released to freelance'
        );
    }
    @IsTest
    static void updateInterestedResourceStatusKeepRetractedTest() {
        Hot_interestedresource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c
            FROM Hot_interestedresource__c
        ];
        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceAppointmentId = interestedResource.ServiceAppointment__c;
        assignedResource.ServiceResourceId = interestedResource.ServiceResource__c;
        insert assignedResource;

        interestedResource = [SELECT Id, Status__c, ServiceAppointment__c FROM Hot_interestedresource__c];
        interestedResource.Status__c = 'Retracted Interest';

        ServiceAppointment sa = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Id = :interestedResource.ServiceAppointment__c
        ];
        sa.Status = 'None';
        update sa;
        sa.Status = 'Released to Freelance';
        update sa;

        System.assertEquals(
            'Retracted Interest',
            interestedResource.Status__c,
            'Should have kept their original status when released to freelance'
        );
    }
}
