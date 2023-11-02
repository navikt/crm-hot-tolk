@isTest
private class HOT_NotificationHandlerTest {
    @testSetup
    static void setup() {
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

    @isTest
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
    @isTest
    private static void prepareNotificationTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Test', workType);
        insert request;

        // Arrange
        String title = 'Test Title';
        String body = 'Test Body';
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Id targetId = request.Id; // Replace with a valid Id

        // Act
        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationType.Id,
            targetId
        );
    }
}
