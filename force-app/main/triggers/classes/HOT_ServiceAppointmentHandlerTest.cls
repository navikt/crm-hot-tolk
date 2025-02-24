@IsTest
private class HOT_ServiceAppointmentHandlerTest {
    @testSetup
    static void setup() {
        TestDataFactory.getPublicGroup('HMS Troms og Finmark', 'group_4719');
        TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'Thread__c');
        TestDataFactory.getPublicGroup('HMS Nordland', 'group_4718');
        TestDataFactory.getQueue('HMS Nordland', 'queue_4718', 'Thread__c');

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        insert serviceResource;
        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Name = 'Test';
        resource.Service_Resource__c = serviceResource.Id;
        insert resource;

        HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
        resourceMember.Resource__c = resource.Id;
        resourceMember.Service_Resource__c = serviceResource.Id;
        insert resourceMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        request.PreferredResource1__c = resource.Id;
        request.NumberOfInterpreters__c = 3;
        insert request;

        request.Status__c = 'Godkjent';
        update request;
    }

    @IsTest
    static void setStatusDefaultTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Status
            FROM ServiceAppointment
            WHERE HOT_PreferredResource__c != NULL
        ];
        System.assertEquals('None', serviceAppointment.Status, 'Default status was not set on ServiceAppointment.');
    }

    @IsTest
    static void setOwnerTest() {
        HOT_Request__c request = [SELECT OwnerId FROM HOT_Request__c];
        ServiceAppointment serviceAppointment = [
            SELECT OwnerId
            FROM ServiceAppointment
            WHERE HOT_PreferredResource__c != NULL
        ];
        System.assertEquals(
            request.OwnerId,
            serviceAppointment.OwnerId,
            'Owner of ServiceAppointment was not set to owner of Request.'
        );
    }

    @IsTest
    public static void ownerOnThreadChangeServiceAppointmentTest() {
        Group tromsOgFinnmarkQueue = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'HMS Troms og Finmark'
            LIMIT 1
        ];

        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, OwnerId
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.OwnerId = serviceAppointment.OwnerId;
        insert thread;

        thread = [
            SELECT OwnerId, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];

        Test.startTest();
        System.assertEquals(serviceAppointment.OwnerId, thread.OwnerId, 'Owner was not set correctly');

        serviceAppointment.OwnerId = tromsOgFinnmarkQueue.Id;
        update serviceAppointment;
        Test.stopTest();

        thread = [
            SELECT OwnerId, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];
        System.assertEquals(tromsOgFinnmarkQueue.Id, thread.OwnerId, 'Owner was not set correctly');
    }

    @IsTest
    public static void dispatcherOnThreadChangeServiceAppointmentTest() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        insert admin;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_DispatcherNew__c
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.HOT_Dispatcher__c = serviceAppointment.HOT_DispatcherNew__c;
        insert thread;

        thread = [
            SELECT HOT_Dispatcher__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];

        Test.startTest();
        System.assertEquals(
            serviceAppointment.HOT_DispatcherNew__c,
            thread.HOT_Dispatcher__c,
            'Dispatcher was not set correctly'
        );

        serviceAppointment.HOT_DispatcherNew__c = admin.Id;
        update serviceAppointment;

        thread = [
            SELECT HOT_Dispatcher__c, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointment.Id
        ];
        Test.stopTest();
        System.assertEquals(
            serviceAppointment.HOT_DispatcherNew__c,
            thread.HOT_Dispatcher__c,
            'Dispatcher was not set correctly'
        );
    }

    @IsTest
    static void cancelServiceAppointment() {
        ServiceAppointment sa = [
            SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        sa.HOT_CanceledByInterpreter__c = true;
        update sa;

        //Checking if SA is cancelled etc
        system.assertEquals(true, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to true');

        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user2 = HOT_TestDataFactory.createUser('User2', profile);
        insert user2;

        ServiceResource sr = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert sr;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
        insert ar;

        sa = [
            SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
            LIMIT 1
        ];

        //Checks if HOT_CancelledByInterpreter is no longer checked
        System.assertEquals(false, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to false');
    }

    @IsTest
    static void testRemoveAssignedResourceCancel() {
        Test.startTest();
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Canceled';
        update sa;
        Test.stopTest();
        List<AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        sa = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :sa.id];
        System.assertEquals(0, arList.size(), 'Could not delete AR');
        System.assertEquals('Canceled', sa.Status, 'Service Appointment did not retain correct status');
    }
    @IsTest
    static void testRemoveAssignedResourceNone() {
        Test.startTest();
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert ar;

        sa.Status = 'Dispatched';
        update sa;

        sa.Status = 'None';
        update sa;
        Test.stopTest();
        List<AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        sa = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :sa.id];
        System.assertEquals(0, arList.size(), 'Could not delete AR');
        System.assertEquals('None', sa.Status, 'Service Appointment did not retain correct status');
    }

    @IsTest
    private static void testCreateHistoricallyAssignedResources_addResource() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('TEST', profile);
        insert user;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;

        Test.startTest();
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );

        //Added Resource
        insert assignedResource;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );

        HOT_HistoricallyAssignedResource__c prevHAR = harList[0];
    }

    @IsTest
    private static void testCreateHistoricallyAssignedResources_statusChange() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;

        //Change status on ServiceAppointment
        serviceAppointment.Status = 'Dispatched';
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE Status__c = 'Tildelt'
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
        System.assertEquals('Tildelt', harList[0].Status__c, 'Status har ikke blitt satt korrekt på HAR');
    }
    @IsTest
    private static void testCreateHistoricallyAssignedResources_resourceChange() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user2', profile);
        insert user;
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource2;

        assignedResource = [
            SELECT Id, ServiceResourceId, ServiceAppointmentId
            FROM AssignedResource
            WHERE Id = :assignedResource.Id
        ];
        assignedResource.ServiceResourceId = resource2.Id;

        Test.startTest();
        update assignedResource;
        Test.stopTest();

        //Old resource
        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE Status__c = 'Tolk tatt av oppdraget'
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
        System.assertEquals(
            'Tolk tatt av oppdraget',
            harList[0].Status__c,
            'Status har ikke blitt satt korrekt på HAR'
        );

        //New resource
        harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE ServiceResource__c = :resource2.Id
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource2.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
    }

    @IsTest
    private static void testCreateHistoricallyAssignedResources_removedResource() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceResource resource = [SELECT Id FROM ServiceResource];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;

        //Remove assigned resource
        Test.startTest();
        delete assignedResource;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
            WHERE Status__c = 'Tolk tatt av oppdraget'
        ];
        System.assertEquals(1, harList.size(), 'Det ble ikke opprette en Historically Assigned Resource');
        System.assertEquals(resource.Id, harList[0].ServiceResource__c, 'HAR ble ikke knyttet til korrekt ressurs');
        System.assertEquals(
            serviceAppointment.Id,
            harList[0].ServiceAppointment__c,
            'HAR ble ikke knyttet til korrekt oppdrag'
        );
        System.assertEquals(
            'Tolk tatt av oppdraget',
            harList[0].Status__c,
            'Status har ikke blitt satt korrekt på HAR'
        );
    }

    @IsTest
    private static void testDoNotCreateHAR() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id];

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('TEST', profile);
        insert user;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;

        serviceAppointment.Status = 'Cancel';
        serviceAppointment.HOT_DoNotCreateHAR__c = true;
        update serviceAppointment;
        Test.stopTest();

        List<HOT_HistoricallyAssignedResource__c> harList = [
            SELECT Id, ServiceResource__c, ServiceAppointment__c, Status__c
            FROM HOT_HistoricallyAssignedResource__c
        ];
        serviceAppointment = [
            SELECT Id, HOT_DoNotCreateHAR__c
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
        ];

        System.assertEquals(1, harList.size());
        System.assertEquals(false, serviceAppointment.HOT_DoNotCreateHAR__c);
    }
    @IsTest
    private static void testGetTranslatedStatus() {
        Map<String, String> correctStatuses = new Map<String, String>();
        correctStatuses.put('', '');
        correctStatuses.put('Annul', 'Annullert');
        correctStatuses.put('Canceled', 'Avlyst av bruker');
        correctStatuses.put('Cannot Complete', 'Udekket');
        correctStatuses.put('Completed', 'Dekket');
        correctStatuses.put('Dispatched', 'Tildelt');
        correctStatuses.put('In Progress', 'Pågår');
        correctStatuses.put('None', 'Åpen');
        correctStatuses.put('Released to Freelance', 'Frigitt til frilanstolker');
        correctStatuses.put('Scheduled', 'Reservert');
        for (String key : correctStatuses.keySet()) {
            System.assertEquals(correctStatuses.get(key), HOT_ServiceAppointmentHandler.getTranslatedStatus(key));
        }
    }
    @IsTest
    static void preserveScheduledTimes_onUpdate() {
        ServiceAppointment sa = [
            SELECT Id, Status, SchedEndTime, SchedStartTime, EarliestStartTime, DueDate
            FROM ServiceAppointment
            LIMIT 1
        ];
        datetime startTime = Datetime.now().addHours(1);
        datetime endTime = Datetime.now().addHours(2);
        sa.EarliestStartTime = startTime;
        sa.DueDate = endTime;
        sa.SchedStartTime = startTime;
        sa.SchedEndTime = endTime;
        sa.Status = 'Cannot Complete';
        update sa;

        sa = [SELECT Id, Status, SchedEndTime, SchedStartTime FROM ServiceAppointment WHERE Id = :sa.Id];

        system.assertEquals(startTime, sa.SchedStartTime, 'Start time not set!');
        system.assertEquals(endTime, sa.SchedEndTime, 'End time not set');
        system.assertEquals('Cannot Complete', sa.Status, 'Status not set');

        // Altering status to None/Åpen - should preserve start/end times
        sa.Status = 'None';
        update sa;

        sa = [SELECT Id, Status, SchedEndTime, SchedStartTime FROM ServiceAppointment WHERE Id = :sa.Id];
        system.assertEquals(startTime, sa.SchedStartTime, 'Start time not set!');
        system.assertEquals(endTime, sa.SchedEndTime, 'End time not set');
        system.assertEquals('None', sa.Status, 'Status not set');
    }

    @IsTest
    static void updateScheduledTimes_onUpdate() {
        ServiceAppointment sa = [
            SELECT Id, EarliestStartTime, DueDate, SchedEndTime, SchedStartTime
            FROM ServiceAppointment
            LIMIT 1
        ];
        sa.EarliestStartTime = Datetime.now().addHours(2);
        sa.DueDate = Datetime.now().addHours(3);
        update sa;

        sa = [
            SELECT Id, SchedEndTime, SchedStartTime, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];
        system.assertEquals(sa.SchedStartTime, sa.EarliestStartTime, 'SchedStart time not set!');
        system.assertEquals(sa.SchedEndTime, sa.DueDate, 'SchedEnd not set');
    }

    @IsTest
    private static void testReleaseToFreelance() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, Status, SchedStartTime, Street, HOT_PreferredResource__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        interestedResource.Status__c = 'Not Assigned';
        insert interestedResource;
        serviceAppointment.Status = 'Released to Freelance';
        serviceAppointment.HOT_PreferredResource__c = null;
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        ServiceAppointment releasedServiceAppointment = [
            SELECT
                Id,
                Status,
                Subject,
                HOT_FreelanceSubject__c,
                HOT_DeadlineDate__c,
                HOT_IsEmployedInterpreter__c,
                HOT_IsReleasedToFreelance__c,
                HOT_ReleaseDate__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        System.assertEquals('Released to Freelance', releasedServiceAppointment.Status, 'Failed to update status');
        System.assertEquals(
            releasedServiceAppointment.Subject,
            releasedServiceAppointment.HOT_FreelanceSubject__c,
            'Freelance Subject was not set'
        );
        System.assertEquals(
            false,
            releasedServiceAppointment.HOT_IsEmployedInterpreter__c,
            'Employed interpreter was not set to false'
        );
        System.assertEquals(
            true,
            releasedServiceAppointment.HOT_IsReleasedToFreelance__c,
            'Freelance interpreter was not set to true'
        );
        System.assertEquals(
            Date.today(),
            releasedServiceAppointment.HOT_ReleaseDate__c,
            'Release date was not set to today'
        );

        HOT_InterestedResource__c updatedInterestedResource = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResource.Id
        ];
        System.assertEquals(
            'Interested',
            updatedInterestedResource.Status__c,
            'InterestedResource status was not updated'
        );

        //Test Retract
        releasedServiceAppointment.Status = 'None';
        update releasedServiceAppointment;
        releasedServiceAppointment = [
            SELECT Id, Status, HOT_IsEmployedInterpreter__c, HOT_IsReleasedToFreelance__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals('None', releasedServiceAppointment.Status, 'Failed to update status');
        System.assertEquals(
            true,
            releasedServiceAppointment.HOT_IsEmployedInterpreter__c,
            'Employed interpreter was not set to true'
        );
        System.assertEquals(
            false,
            releasedServiceAppointment.HOT_IsReleasedToFreelance__c,
            'Freelance interpreter was not set to false'
        );
    }

    @IsTest
    public static void serviceAppointmentCompletedWithoutActualTimes() {
        ServiceAppointment serviceAppointment = [SELECT Id, Status, HOT_Request__c FROM ServiceAppointment LIMIT 1];
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c WHERE Id = :serviceAppointment.HOT_Request__c];
        request.Type__c = 'ImageInterpreter';
        update request;
        serviceAppointment.Status = 'Completed';
        update serviceAppointment;
        serviceAppointment = [
            SELECT Id, ActualStartTime, ActualEndTime, SchedStartTime, SchedEndTime, HOT_IsImageInterpreter__c
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.ActualStartTime,
            'Could not set Actual Start Time'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.ActualEndTime,
            'Could not set Actual End Time'
        );
        System.assertEquals(serviceAppointment.HOT_IsImageInterpreter__c, true, 'Could not set imgint');
    }

    @IsTest
    public static void startHourAndEndHourSameTimeAsScheduledDateTimes() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, EarliestStartTime, DueDate, HOT_StartHour__c, HOT_EndHour__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.EarliestStartTime = DateTime.now();
        serviceAppointment.DueDate = DateTime.now();
        update serviceAppointment;
        serviceAppointment = [
            SELECT Id, EarliestStartTime, DueDate, HOT_StartHour__c, HOT_EndHour__c
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(
            serviceAppointment.EarliestStartTime.format('HH', 'Europe/Oslo'),
            serviceAppointment.HOT_StartHour__c,
            'Start time ble ikke satt riktig'
        );
        System.assertEquals(
            serviceAppointment.DueDate.format('HH', 'Europe/Oslo'),
            serviceAppointment.HOT_EndHour__c,
            'End time ble ikke satt riktig'
        );
    }

    @IsTest
    public static void addContentDocumentLinkToServiceAppointment() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_Request__c, ParentRecordId
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        ContentVersion contentVersion = new ContentVersion(
            Title = 'a picture',
            PathOnClient = 'Pic.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = request.Id
        );
        insert contentDocumentLink;

        ServiceAppointment serviceAppointmentCopy = serviceAppointment.Clone(false, true, false, false);
        Test.startTest();
        insert serviceAppointmentCopy;
        Test.stopTest();

        ContentDocumentLink contentDocumentLink_ServiceAppointment = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :serviceAppointmentCopy.Id
            LIMIT 1
        ];

        Id requestContentDocumentid = contentDocumentLink.ContentDocumentId;
        Id serviceAppointmentContentDocumentId = contentDocumentLink_ServiceAppointment.ContentDocumentId;

        System.assertEquals(
            requestContentDocumentId,
            serviceAppointmentContentDocumentId,
            'ContentDocumentId fra request og serviceAppointment stemmer ikke overens.'
        );
    }

    @IsTest
    public static void actualTimeChanged() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, ActualStartTime, ActualEndTime
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.ActualStartTime = DateTime.now();
        serviceAppointment.ActualEndTime = DateTime.now().addHours(1);
        Test.startTest();
        update serviceAppointment;
        Test.stopTest();
        serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.ActualStartTime,
            'Planlagt starttid ble ikke satt til faktisk starttid'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.ActualEndTime,
            'Planlagt sluttid ble ikke satt til faktisk sluttid'
        );
    }

    @IsTest
    public static void setArchiveAsOwnerTest() {
        ServiceAppointment serviceAppointment = [SELECT Id, OwnerId FROM ServiceAppointment LIMIT 1];

        Group archive = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'HOT Arkiv' LIMIT 1];
        System.assertNotEquals(
            archive.Id,
            serviceAppointment.OwnerId,
            'The owner was "HOT Arkiv". Should be different owner.'
        );

        Test.startTest();
        serviceAppointment.HOT_DelPol_IsHideRecord__c = true;
        update serviceAppointment;
        Test.stopTest();

        ServiceAppointment updatedServiceAppointment = [
            SELECT Id, OwnerId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];
        System.assertEquals(
            archive.Id,
            updatedServiceAppointment.OwnerId,
            'The owner was not changed to "HOT Arkiv" as expected.'
        );
    }

    @IsTest
    public static void checkIfHOTAccountFieldIsEqualToAccountOnInsert() {
        ServiceAppointment serviceAppointment = [SELECT Id, AccountId, HOT_Account__c FROM ServiceAppointment LIMIT 1];
        System.assertEquals(
            serviceAppointment.AccountId,
            serviceAppointment.HOT_Account__c,
            'SA HOT_Account__c was not set correctly.'
        );
    }

    @IsTest
    public static void actualStartTimesShouldBeSchedStartTimesTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, AccountId, ActualStartTime, ActualEndTime, SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            LIMIT 1
        ];

        serviceAppointment.ActualStartTime = null;
        serviceAppointment.ActualEndTime = null;
        serviceAppointment.Status = 'Completed';

        Test.startTest();
        update serviceAppointment;
        Test.stopTest();

        serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime, Status
            FROM serviceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        System.assertEquals(
            serviceAppointment.SchedStartTime,
            serviceAppointment.ActualStartTime,
            'Expected SchedStartTime and ActualStartTime to be the same'
        );
        System.assertEquals(
            serviceAppointment.SchedEndTime,
            serviceAppointment.ActualEndTime,
            'Expected SchedEndTime and ActualEndTime to be the same'
        );
    }
}
