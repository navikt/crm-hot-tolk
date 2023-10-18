@isTest
private class HOT_ServiceAppointmentNotificationTest {
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
        serviceResource.HOT_IsEmployedInterpreter__c = true;
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

        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource serviceResource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        serviceResource2.HOT_IsEmployedInterpreter__c = true;
        insert serviceResource2;
        serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(serviceResource2, serviceTerritory);
        insert serviceTerritoryMember;

        HOT_Resource__c resource2 = new HOT_Resource__c();
        resource2.Name = 'Test2';
        resource2.Service_Resource__c = serviceResource2.Id;
        insert resource2;

        HOT_ResourceMember__c resourceMember2 = new HOT_ResourceMember__c();
        resourceMember2.Resource__c = resource2.Id;
        resourceMember2.Service_Resource__c = serviceResource2.Id;
        insert resourceMember2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        request.PreferredResource1__c = resource.Id;
        request.NumberOfInterpreters__c = 3;
        insert request;

        request.Status__c = 'Godkjent';
        update request;
    }

    @isTest
    private static void canceledByUserTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        WorkOrder wo = [
            SELECT Id, AppointmentNumber, EarliestStartTime
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Test.startTest();
        HOT_WorkOrderNotification.canceledByUser(notificationType, wo, recipients);
        Test.stopTest();
    }
}
