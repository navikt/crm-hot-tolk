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
        Account acc = HOT_TestDataFactory.createAccount(true);
        insert acc;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        request.PreferredResource1__c = resource.Id;
        request.Orderer__c = acc.Id;
        request.NumberOfInterpreters__c = 3;
        insert request;

        request.Status__c = 'Godkjent';
        update request;
    }

    @isTest
    private static void notifyResourceAndDispatcherTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        List<ServiceResource> testResources = [
            SELECT Id, HOT_IsEmployedInterpreter__c
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
        ];

        Test.startTest();

        //AR på SA
        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            testResources[0].Id
        );

        insert assignedResource;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        system.assertEquals('Dispatched', serviceAppointment.Status, 'Could not set status');

        //Bytte av AR
        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, testResources[1].Id);
        update serviceAppointment;

        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        //Avlyst av tolk
        serviceAppointment.HOT_IsNotifyDispatcher__c = true;
        serviceAppointment.HOT_CanceledByInterpreter__c = true;
        update serviceAppointment;

        serviceAppointment = [
            SELECT Id, HOT_CanceledByInterpreter__c, HOT_IsNotifyDispatcher__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        system.assertEquals(
            true,
            serviceAppointment.HOT_CanceledByInterpreter__c,
            'Could not set HOT_CanceledByInterpreter__c'
        );

        //Avlyst på vegne av bruker
        serviceAppointment.HOT_IsNotifyDispatcher__c = true;
        serviceAppointment.Status = 'Canceled';
        update serviceAppointment;

        serviceAppointment = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :serviceAppointment.Id LIMIT 1];

        system.assertEquals('Canceled', serviceAppointment.Status, 'Could not set Status');

        Test.stopTest();
    }

    @isTest
    private static void resourceCanceledTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, Subject
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
        HOT_ServiceAppointmentNotification.resourceCanceled(notificationType, serviceAppointment, recipients);
        Test.stopTest();
    }

    @isTest
    private static void notifyUserOnChangedResourceTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, EarliestStartTime
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        Test.startTest();
        HOT_ServiceAppointmentNotification.notifyUserOnChangedResource(serviceAppointment);
        Test.stopTest();
    }

    @isTest
    private static void canceledByUserTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, EarliestStartTime
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        //Set<Id> srIds = new Set<Id>([SELECT Id FROM ServiceResource LIMIT 1]);
        Set<Id> srIds = (new Map<Id, ServiceResource>([SELECT Id FROM ServiceResource LIMIT 1])).keySet();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Test.startTest();
        HOT_ServiceAppointmentNotification.canceledByUser(notificationType, serviceAppointment, srIds, recipients);
        Test.stopTest();
    }

    @isTest
    private static void timeChangedTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        //Set<Id> saIds = new Set<Id>([SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]);
        Set<Id> saIds = (new Map<Id, ServiceAppointment>(
                [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]
            ))
            .keySet();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Test.startTest();
        HOT_ServiceAppointmentNotification.timeChanged(notificationType, saIds, recipients);
        Test.stopTest();
    }

    @isTest
    private static void addressChangedTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_InterpretationStreet__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        serviceAppointment.HOT_InterpretationStreet__c = 'Tolkeveien 123';
        update serviceAppointment;

        Set<Id> saIds = (new Map<Id, ServiceAppointment>(
                [SELECT HOT_InterpretationStreet__c FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]
            ))
            .keySet();
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Test.startTest();
        HOT_ServiceAppointmentNotification.timeChanged(notificationType, saIds, recipients);
        Test.stopTest();
    }
}
