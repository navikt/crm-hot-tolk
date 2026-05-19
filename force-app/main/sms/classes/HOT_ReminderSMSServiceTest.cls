@IsTest
private class HOT_ReminderSMSServiceTest {
    @testSetup
    static void setup() {

        myTriggers.disable(UserDefaultValuesHandler.class);
        myTriggers.disable(UserProfileHandler.class);
        myTriggers.disable(UserRegionHandler.class);
        myTriggers.disable(UserRoleAssignmentHandler.class);
        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(
            PersonHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.BEFORE_INSERT }
        );
        myTriggers.disable(
            PersonHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.BEFORE_UPDATE }
        );
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrMobilePhone__c = '00000000';
        person.HOT_NotificationChannel__c = 'SMS';
        insert person;
        Account account = [SELECT Id FROM Account];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.StartTime__c = request.StartTime__c.addDays(3);
        request.EndTime__c = request.EndTime__c.addDays(3);
        request.OrdererPhone__c = '00000000';
        request.IsOrdererWantStatusUpdateOnSMS__c = true;
        request.Orderer__c = account.Id;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        request2.Account__c = account.Id;
        request2.StartTime__c = request2.StartTime__c.addDays(3);
        request2.EndTime__c = request2.EndTime__c.addDays(3);
        request2.OrdererPhone__c = '00000000';
        request2.IsOrdererWantStatusUpdateOnSMS__c = true;
        request2.Orderer__c = account.Id;
        request2.NumberOfInterpreters__c = 3;

        HOT_Request__c[] requests = new List<HOT_Request__c>{ request, request2 };
        insert requests;

        request.Status__c = 'Godkjent';
        request2.Status__c = 'Godkjent';

        update requests;

        WorkOrder workOrder = [
            SELECT
                Id,
                Status,
                Account.CRM_Person__r.HOT_NotificationChannel__c,
                Account.CRM_Person__r.HOT_MobilePhone__c,
                StartDate,
                EndDate,
                HOT_Request__r.IsNotNotifyAccount__c
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
        ];
        workOrder.Status = 'Dispatched';
        workOrder.StartDate = workOrder.StartDate.addDays(-2);
        workOrder.EndDate = workOrder.EndDate.addDays(-2);
        update workOrder;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        serviceResource.HOT_MobilePhoneOverride__c = '12345678';
        serviceResource.ResourceType = 'A';
        insert serviceResource;
    }

    @IsTest
    static void reminderSMSTest() {
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Account.CRM_Person__r.HOT_MobilePhone__c, StartDate, EndDate
            FROM WorkOrder
        ];
        Test.startTest();
        HOT_ReminderSMSService.reminderSMS(workOrders);
        Test.stopTest();
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }

    @IsTest
    static void notifyUserOnOrderSMSTest() {
        List<HOT_Request__c> requests = [
            SELECT
                Id,
                Account__c,
                IsSerieoppdrag__c,
                SeriesPeriod__c,
                Account__r.CRM_Person__r.HOT_MobilePhone__c,
                IsNotifyUserOnOrder__c,
                StartTime__c,
                EndTime__c
            FROM HOT_Request__c
        ];
        System.assertEquals(2, requests.size(), 'Could not create request-records');
        Test.startTest();
        HOT_ReminderSMSService.notifyUserOnOrderSMS(requests);
        Test.stopTest();
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }
    @IsTest
    static void notifyUserOnOrderSeriesSMSTest() {
        myTriggers.disable(
            PersonHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.BEFORE_INSERT }
        );
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        Test.startTest();
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrMobilePhone__c = '00000000';
        person.HOT_NotificationChannel__c = 'SMS';
        insert person;
        Account account = [SELECT Id FROM Account LIMIT 1];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = account.Id;
        request.Account__c = account.Id;
        request.NumberOfWorkOrders__c = 2;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        // To create child records
        request.Status__c = 'Godkjent';
        update request;

        List<HOT_Request__c> requests = [
            SELECT
                Id,
                Account__c,
                IsSerieoppdrag__c,
                SeriesPeriod__c,
                Account__r.CRM_Person__r.HOT_MobilePhone__c,
                IsNotifyUserOnOrder__c,
                StartTime__c,
                EndTime__c
            FROM HOT_Request__c
            WHERE Id = :request.Id AND IsSerieoppdrag__c = TRUE
        ];
        HOT_ReminderSMSService.notifyUserOnOrderSMS(requests);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        Test.stopTest();
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @IsTest
    static void sendSMSToOrdererOnStatusUpdateTest() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                HOT_Request__r.Type__c,
                StartDate,
                EndDate,
                HOT_Request__r.IsNotNotifyAccount__c,
                Status,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        Test.startTest();
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        Test.stopTest();
        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @IsTest
    static void sendSMSToInterpreterCancelledByUserTest() {
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        Test.startTest();
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
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

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.HOT_MobilePhoneOverride__c = '12345678';
        insert resource;

        ServiceResource sr = [
            SELECT RelatedRecordId, HOT_MobilePhone__c
            FROM ServiceResource
            WHERE RelatedRecordId = :currentUser.Id
        ];
        Set<Id> srIds = new Set<Id>();
        srIds.add(resource.Id);
        Set<Id> saIds = new Set<Id>();
        saIds.add(serviceAppointment.Id);

        HOT_ReminderSMSService.sendSMSToInterpreterOnCanceledByUser(saIds, srIds);
        Test.stopTest();
        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }

    @IsTest
    static void sendSMSToInterpreterOnScreenInterpretationTest() {
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{
                System.TriggerOperation.AFTER_INSERT,
                System.TriggerOperation.AFTER_UPDATE
            }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();
        Test.startTest();
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.HOT_MobilePhoneOverride__c = '12345678';
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert assignedResource;

        HOT_ReminderSMSService.sendSMSToInterpreterOnScreenInterpretation(saIds);
        Test.stopTest();
    }
    @IsTest
    static void sendSMSToInterpreterOnTimeChangedTest() {
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();
        Test.startTest();
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.HOT_MobilePhoneOverride__c = '12345678';
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert assignedResource;

        HOT_ReminderSMSService.sendSMSToInterpreterOnTimeChanged(saIds);
        Test.stopTest();
    }
    @IsTest
    static void sendSMSToInterpreterOnAddressChangedTest() {
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.HOT_MobilePhoneOverride__c = '12345678';
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert assignedResource;
        HOT_ReminderSMSService.sendSMSToInterpreterOnAddressChanged(saIds);
        Test.stopTest();
    }
    @IsTest
    static void sendSMSToInterpreterOnAddedOrChangedTest() {
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.HOT_MobilePhoneOverride__c = '12345678';
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource;

        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert assignedResource;
        HOT_ReminderSMSService.sendSMSToInterpreterOnAddedOrChanged(saIds);
        Test.stopTest();
    }
    @IsTest
    static void sendSMSToInterpreterOnResourceChangedTest() {
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        Set<Id> saIds = (new Map<Id, ServiceAppointment>([SELECT Id FROM ServiceAppointment LIMIT 1])).keySet();

        Test.startTest();
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
        resource.HOT_MobilePhoneOverride__c = '12345678';
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
        insert assignedResource;
        HOT_ReminderSMSService.sendSMSToInterpreterOnResourceChanged(saIds);
        Test.stopTest();
    }

    @IsTest
    static void sendSMSOnNewFilesAddedTest() {
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, serviceTerritory);
        Test.startTest();
        ServiceAppointment sa = [
            SELECT Id, AppointmentNumber, HOT_ServiceResource__r.AccountId, HOT_ServiceResource__r.HOT_MobilePhone__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, sr.Id);
        insert assignedResource;

        HOT_ReminderSMSService.sendSMSOnNewFilesAdded(new List<ServiceAppointment>{ sa });
        Test.stopTest();
    }
    @IsTest
    static void sendSMSOnNewWantedSRTest() {
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'TEST' LIMIT 1];
        Test.startTest();
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, sr.Id);
        insert ir;

        Set<Id> irIds = (new Map<Id, HOT_InterestedResource__c>([SELECT Id FROM HOT_InterestedResource__c LIMIT 1]))
            .keySet();

        HOT_ReminderSMSService.sendSMSOnNewWantedSR(irIds);
        Test.stopTest();
    }
    @IsTest
    static void cancelledByUserConstructMessage() {
        ServiceAppointment sa = [
            SELECT Id, Status, AppointmentNumber, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE Subject = 'TEST'
            LIMIT 1
        ];

        Test.startTest();
        String res = HOT_ReminderSMSService.constructMessageToInterpreter(sa, 'CanceledByUser');
        Boolean result = res.contains('avlyst');
        System.assertEquals(true, result, 'Did not create the correct message');

        Test.stopTest();
    }
    @IsTest
    static void getRecipientOnThreadTest() {
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
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

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        resource.HOT_MobilePhoneOverride__c = '12345678';
        resource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        update resource;
        insert HOT_TestDataFactory.createServiceTerritoryMember(resource, serviceTerritory);

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Account__c = currentUser.AccountId;
        thread.CRM_Related_Object__c = request.Id;
        thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        insert thread;

        String result = HOT_ReminderSMSService.getRecipientByThreadIdMap(new List<Thread__c>{ thread }).get(thread.Id);
        System.assertEquals('12345678', result, 'Did not get correct recipient');

        Test.stopTest();
    }
    @IsTest
    static void getRecipientOnThreadUserTest() {
        myTriggers.disable(
            PersonHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.BEFORE_INSERT }
        );
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest();
        Person__c person = HOT_TestDataFactory.createPerson();
        person.HOT_NotificationChannel__c = 'SMS';
        insert person;
        Account account = [SELECT Id FROM Account LIMIT 1];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = account.Id;
        request.Account__c = account.Id;
        request.NumberOfWorkOrders__c = 2;
        insert request;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Account__c = currentUser.AccountId;
        thread.CRM_Related_Object__c = request.Id;
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        insert thread;

        String result = HOT_ReminderSMSService.getRecipientByThreadIdMap(new List<Thread__c>{ thread }).get(thread.Id);
        System.assertEquals(null, result, 'Did not get correct recipient');

        Test.stopTest();
    }
    @IsTest
    static void getRecipientOnThreadOrdererTest() {
        myTriggers.disable(
            PersonHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.BEFORE_INSERT }
        );
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest();
        Person__c person = HOT_TestDataFactory.createPerson();
        person.HOT_NotificationChannel__c = 'SMS';
        insert person;
        Account account = [SELECT Id FROM Account LIMIT 1];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Orderer__c = account.Id;
        request.Account__c = account.Id;
        request.NumberOfWorkOrders__c = 2;
        insert request;

        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Account__c = currentUser.AccountId;
        thread.CRM_Related_Object__c = request.Id;
        thread.CRM_Thread_Type__c = 'HOT_BESTILLER-FORMIDLER';
        insert thread;

        String result = HOT_ReminderSMSService.getRecipientByThreadIdMap(new List<Thread__c>{ thread }).get(thread.Id);
        System.assertEquals(null, result, 'Did not get correct recipient');

        Test.stopTest();
    }

    @IsTest
    static void sendSMSOnInterpreterChangeTest() {
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];

        Set<Id> workOrderIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            workOrderIds.add(wo.Id);
        }
        Test.startTest();
        HOT_ReminderSMSService.sendSMSOnInterpreterChange(workOrderIds, 'Tolk Tolkersen');
        Test.stopTest();

        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }

    @IsTest
    static void sendSMSToOrdererOnStatusUpdateTest2() {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                HOT_Request__r.Type__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        Test.startTest();
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        Test.stopTest();
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        System.assertEquals(2, smsList.size(), 'Could not create sms-record');
    }

    @IsTest
    static void sendSMSToOrdererOnStatusUpdateTestInterpreterNames() {
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.OrdererPhone__c,
                HOT_Request__r.Type__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c,
                Account.CRM_Person__r.HOT_MobilePhone__c
            FROM WorkOrder
        ];
        //flyttet pga limits
        Test.startTest();
        ServiceResource interpreter = [SELECT Id, Name FROM ServiceResource LIMIT 1];
        interpreter.Name = 'InterpreterName';

        HOT_DatabaseOperations.updateRecords(interpreter);

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_ServiceResource__c, Status
            FROM ServiceAppointment
        ];

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_ServiceResource__c = interpreter.Id;
            serviceAppointment.Status = 'Dispatched';
        }

        HOT_DatabaseOperations.updateRecords(serviceAppointments);

        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);

        String message = [SELECT Id, Message__c FROM SMS__c LIMIT 1].Message__c;
        Test.stopTest();
        System.assert(message.contains('InterpreterName'), 'Could not create sms-record');
    }

    @IsTest
    static void sendSMSToOrdererOnStatusUpdateSMSToAccountTest() {
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c][0];
        request.Type__c = 'Me';
        request.Orderer__c = account.Id;
        update request;
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                Account.CRM_Person__r.HOT_MobilePhone__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.Type__c,
                HOT_Request__r.OrdererPhone__c,
                StartDate,
                EndDate,
                HOT_Request__r.IsNotNotifyAccount__c,
                Status,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        Test.startTest();
        String personPhoneNumber = workOrders[0].Account.CRM_Person__r.HOT_MobilePhone__c;
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        Test.stopTest();
        String smsPhoneNumber = [SELECT Id, Recipient__c FROM SMS__c LIMIT 1].Recipient__c;
        System.assertEquals(personPhoneNumber, smsPhoneNumber, 'SMS was not sent to the user');
    }

    @IsTest
    static void sendSMSToOrdererOnStatusUpdateSMSToOtherOrdererTest() {
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = [SELECT Id, Type__c FROM HOT_Request__c][0];
        request.Orderer__c = account.Id;
        update request;
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                Account.CRM_Person__r.HOT_MobilePhone__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.Type__c,
                HOT_Request__r.OrdererPhone__c,
                StartDate,
                EndDate,
                Status,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c
            FROM WorkOrder
        ];
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Cannot Complete';
        }
        Test.startTest();
        String orderPhoneNumber = workOrders[0].HOT_Request__r.OrdererPhone__c;
        update workOrders;
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workOrders);
        Test.stopTest();
        String smsPhoneNumber = [SELECT Id, Recipient__c FROM SMS__c LIMIT 1].Recipient__c;

        System.assertEquals(orderPhoneNumber, smsPhoneNumber, 'SMS was not sent to the user');
    }
    @IsTest
    public static void testSendSMSOnNewMessage() {
        myTriggers.disable(
            PersonHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.BEFORE_INSERT }
        );
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        Test.startTest();
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        ServiceResource serviceResource = [SELECT Id, AccountId, HOT_MobilePhone__c FROM ServiceResource LIMIT 1];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = personAccount.Id;
        request.StartTime__c = request.StartTime__c.addDays(3);
        request.EndTime__c = request.EndTime__c.addDays(3);
        request.Orderer__c = personAccount.Id;
        insert request;
        Thread__c thread1 = new Thread__c(
            RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType(),
            CRM_Account__c = serviceResource.AccountId,
            CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR'
        );
        insert thread1;

        Thread__c thread2 = new Thread__c(
            RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType(),
            CRM_Account__c = serviceResource.AccountId,
            CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR'
        );
        insert thread2;

        Set<Id> threadIds = new Set<Id>{ thread1.Id, thread2.Id };

        HOT_ReminderSMSService.sendSMSOnNewMessage(threadIds);
        List<SMS__c> smsList = [SELECT Id FROM SMS__c];
        Test.stopTest();
        System.assertEquals(0, smsList.size(), 'Should not created SMS');
    }
    @IsTest
    static void sendSMSOnCoInterpreterRemoved() {
        myTriggers.disable(UserDefaultValuesHandler.class);
        myTriggers.disable(UserProfileHandler.class);
        myTriggers.disable(UserRegionHandler.class);
        myTriggers.disable(UserRoleAssignmentHandler.class);
        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        myTriggers.disable(
            HOT_RequestHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_AssignedResourceAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_INSERT }
        );
        myTriggers.disable(
            HOT_ServiceAppointmentAccessHandler.class,
            new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE }
        );
        Test.startTest();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user2', profile);
        insert user;
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsEmployedInterpreter__c = false;
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        serviceResource.HOT_MobilePhoneOverride__c = '12345678';
        serviceResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert serviceResource;
        insert HOT_TestDataFactory.createServiceTerritoryMember(serviceResource, serviceTerritory);
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

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        HOT_ReminderSMSService.sendSMSOnCoInterpreterRemoved(serviceResource.Id, 'Start', 'Slutt');
        Test.stopTest();

        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(1, smsList.size(), 'Could not create sms-record');
    }
}
