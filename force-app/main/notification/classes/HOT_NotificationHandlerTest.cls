@IsTest
private class HOT_NotificationHandlerTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
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
    static void testGetGroupIdByQueueId() {
        Group formidlerGroup = new Group(
            Name = 'HOT group 999011 formidler',
            DeveloperName = 'HOT_group_999011_formidler',
            Type = 'Regular'
        );
        Group queue = new Group(Name = 'Queue 999011', DeveloperName = 'queue_999011', Type = 'Queue');
        insert new List<Group>{ formidlerGroup, queue };

        Map<Id, Id> result = HOT_NotificationHandler.getGroupIdByQueueId(new List<Id>{ queue.Id });

        System.assertEquals(formidlerGroup.Id, result.get(queue.Id));
    }

    @IsTest
    static void malformedQueueNameIsReturnedAsUnresolved() {
        Group queue = new Group(Name = 'Malformed Queue', DeveloperName = 'MalformedQueue', Type = 'Queue');
        insert queue;

        Map<Id, Id> result = HOT_NotificationHandler.getGroupIdByQueueId(new List<Id>{ queue.Id });

        System.assertEquals(null, result.get(queue.Id));
    }

    @IsTest
    private static void testNotifyUsers() {
        Test.startTest();
        ServiceAppointment serviceAppointment = [
            SELECT Id, Status, SchedStartTime, Street
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.Status = 'Canceled';
        serviceAppointment.SchedStartTime = Datetime.now();
        serviceAppointment.Street = 'Street2789462894';
        update serviceAppointment;
        Test.stopTest();
    }
    @IsTest
    private static void prepareNotificationTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Test', workType);
        insert request;

        String title = 'Test Title';
        String body = 'Test Body';
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Id targetId = request.Id;

        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationType.Id,
            targetId
        );

        System.assertNotEquals(null, notification);
        HOT_NotificationHandler.sendNotification(notification, new Set<String>(), request);
    }
}
