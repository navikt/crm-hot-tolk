@IsTest
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
        serviceResource.HOT_IsEmployedInterpreter__c = false;
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        insert serviceResource;
        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Name = 'Test2';
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

    @IsTest
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

        if (testResources.size() < 1) {
            assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, testResources[1].Id);
            update serviceAppointment;
        }

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

    @IsTest
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

    @IsTest
    private static void notifyUserOnChangedResourceTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, EarliestStartTime
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        ServiceResource serviceResourceNew = [SELECT Id FROM ServiceResource WHERE Id != :serviceResource.Id LIMIT 1];
        assignedResource.ServiceResource = serviceResourceNew;
        update assignedResource;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        Test.startTest();
        HOT_ServiceAppointmentNotification.notifyUserOnChangedResource(serviceAppointment);
        Test.stopTest();
    }

    @IsTest
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
    @IsTest
    private static void canceledByUserSMSTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        Test.startTest();
        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, EarliestStartTime, HOT_IsEmployedInterpreter__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        serviceAppointment.HOT_IsEmployedInterpreter__c = false;
        update serviceAppointment;

        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_NotificationChannel__c = 'SMS';
        insert serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        serviceAppointment.Status = 'Canceled';
        update serviceAppointment;
        Set<Id> srIds = new Set<Id>();
        srIds.add(serviceResource.Id);

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        HOT_ServiceAppointmentNotification.canceledByUser(notificationType, serviceAppointment, srIds, recipients);

        Test.stopTest();
    }

    @IsTest
    private static void timeChangedTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        //Set<Id> saIds = new Set<Id>([SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]);
        List<ServiceAppointment> saList = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            saList[0].Id,
            serviceResource.Id
        );
        insert assignedResource;

        DateTime now = DateTime.now();
        DateTime newTime = now.addDays(2);
        DateTime newTime2 = newTime.addHours(2);
        for (ServiceAppointment sa : saList) {
            sa.EarliestStartTime = newTime;
            sa.DueDate = newTime2;
        }
        update saList;
        List<ServiceResource> testResources = [
            SELECT Id, HOT_IsEmployedInterpreter__c
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
        ];

        Test.startTest();

        Set<Id> saIds = (new Map<Id, ServiceAppointment>(
                [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]
            ))
            .keySet();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        HOT_ServiceAppointmentNotification.timeChanged(notificationType, saIds, recipients);
        Test.stopTest();
    }
    @IsTest
    private static void timeChangedSMSTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        //Set<Id> saIds = new Set<Id>([SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]);
        List<ServiceAppointment> saList = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];

        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_NotificationChannel__c = 'SMS';
        insert serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            saList[0].Id,
            serviceResource.Id
        );
        insert assignedResource;

        DateTime now = DateTime.now();
        DateTime newTime = now.addDays(2);
        DateTime newTime2 = newTime.addHours(2);
        for (ServiceAppointment sa : saList) {
            sa.EarliestStartTime = newTime;
            sa.DueDate = newTime2;
            sa.HOT_IsEmployedInterpreter__c = false;
        }
        update saList;

        Test.startTest();

        Set<Id> saIds = (new Map<Id, ServiceAppointment>(
                [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1]
            ))
            .keySet();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        HOT_ServiceAppointmentNotification.timeChanged(notificationType, saIds, recipients);
        Test.stopTest();
    }

    @IsTest
    private static void addressChangedTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert serviceResource;
        Test.startTest();
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
        serviceAppointment.Subject = 'Test';
        insert serviceAppointment;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        serviceAppointment.HOT_InterpretationStreet__c = 'Tolkeveien 123';
        update serviceAppointment;

        Set<Id> saIds = (new Map<Id, ServiceAppointment>(
                [SELECT HOT_InterpretationStreet__c FROM ServiceAppointment WHERE Subject = 'Test' LIMIT 1]
            ))
            .keySet();
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        HOT_ServiceAppointmentNotification.addressChanged(notificationType, saIds, recipients);
        Test.stopTest();
    }

    @IsTest
    private static void notifyInterpretersOnChangedResourceTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        //List<User> users = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 2];
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
            LIMIT 1
        ];
        ServiceResource serviceResourceFreelance = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Flertolksoppdrag med endring av medtolk', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.HOT_Request__c = request.Id;
        serviceAppointment.Subject = 'Flertolksoppdrag med endring av medtolk';
        insert serviceAppointment;

        ServiceAppointment serviceAppointment2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment2.HOT_Request__c = request.Id;
        serviceAppointment2.Subject = 'Flertolksoppdrag med endring av medtolk';
        insert serviceAppointment2;

        Test.startTest();

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            serviceResourceFreelance.Id
        );
        insert assignedResource2;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        serviceAppointment2.Status = 'Dispatched';
        update serviceAppointment2;

        //Freelance notification
        HOT_ServiceAppointmentNotification.notifyInterpretersOnChangedResource(serviceAppointment2);
        //Employee notification
        HOT_ServiceAppointmentNotification.notifyInterpretersOnChangedResource(serviceAppointment);
        Test.stopTest();
    }

    @IsTest
    private static void testFormatTimePeriod() {
        Datetime startDate = Datetime.newInstance(2023, 10, 20, 9, 0, 0);
        Datetime endDate = Datetime.newInstance(2023, 10, 20, 15, 30, 0);

        String result = HOT_ServiceAppointmentNotification.formatTimePeriod(startDate, endDate);

        String expected = '20.10.2023\nKlokkeslett: 09.00 - 15.30';

        System.assertEquals(expected, result, 'The formatted time period is incorrect.');
    }
    @IsTest
    private static void cannotCompleteTest() {
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        Test.startTest();
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

        serviceAppointment.Status = 'Cannot Complete';
        update serviceAppointment;
        Test.stopTest();
    }
    @IsTest
    private static void notifyInterpretersOnCoInterpreterRemovedTest() {
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
        ServiceAppointment serviceAppointment2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment2.HOT_Request__c = request.Id;
        serviceAppointment2.HOT_WorkOrderLineItem__c = workOrderLineItem.Id;
        insert serviceAppointment2;

        Test.startTest();
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
            LIMIT 1
        ];
        ServiceResource serviceResourceFreelance = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            serviceResourceFreelance.Id
        );
        insert assignedResource2;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        serviceAppointment2.Status = 'Dispatched';
        update serviceAppointment2;

        delete assignedResource;
        Test.stopTest();
    }
    @IsTest
    private static void notifyInterpretersOnCoInterpreterChangedTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('admin', profile);
        insert user;
        ServiceResource serviceResourceNew = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResourceNew.HOT_IsEmployedInterpreter__c = false;
        serviceResourceNew.HOT_IsFreelanceInterpreter__c = true;
        serviceResourceNew.Name = 'Test2';
        insert serviceResourceNew;

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
        ServiceAppointment serviceAppointment2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment2.HOT_Request__c = request.Id;
        serviceAppointment2.HOT_WorkOrderLineItem__c = workOrderLineItem.Id;
        insert serviceAppointment2;

        Test.startTest();
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
            LIMIT 1
        ];
        ServiceResource serviceResourceFreelance = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        ServiceResource serviceResourceFreelance2 = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE AND Name = 'Test2'
            LIMIT 1
        ];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            serviceResourceFreelance.Id
        );
        insert assignedResource2;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        serviceAppointment2.Status = 'Dispatched';
        update serviceAppointment2;

        assignedResource.ServiceResource = serviceResourceFreelance2;
        update assignedResource;
        Test.stopTest();
    }
}
