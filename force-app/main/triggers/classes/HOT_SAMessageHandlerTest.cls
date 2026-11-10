@IsTest
private class HOT_SAMessageHandlerTest {
    @TestSetup
    static void makeData() {
        User interpreter;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile profile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
            interpreter = HOT_TestDataFactory.createUser('msgUser', profile);
            insert interpreter;
        }

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory territory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert territory;
        HOT_Request__c firstRequest = HOT_TestDataFactory.createRequest('Første beskjedoppdrag', workType);
        HOT_Request__c secondRequest = HOT_TestDataFactory.createRequest('Andre beskjedoppdrag', workType);
        firstRequest.NumberOfInterpreters__c = 2;
        firstRequest.ServiceTerritory__c = territory.Id;
        secondRequest.ServiceTerritory__c = territory.Id;
        secondRequest.StartTime__c = secondRequest.StartTime__c.addDays(1);
        secondRequest.EndTime__c = secondRequest.EndTime__c.addDays(1);
        insert new List<HOT_Request__c>{ firstRequest, secondRequest };
        firstRequest.Status__c = 'Godkjent';
        secondRequest.Status__c = 'Godkjent';
        update new List<HOT_Request__c>{ firstRequest, secondRequest };

        ServiceResource firstResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        firstResource.HOT_IsFreelanceInterpreter__c = true;
        firstResource.HOT_NotificationChannel__c = 'Push-varsel i appen';
        firstResource.HOT_MobilePhoneOverride__c = '91234567';
        firstResource.HOT_ServiceTerritory__c = territory.Id;
        ServiceResource secondResource = HOT_TestDataFactory.createServiceResource(interpreter.Id);
        secondResource.HOT_IsFreelanceInterpreter__c = true;
        secondResource.HOT_NotificationChannel__c = 'Push-varsel i appen';
        secondResource.HOT_MobilePhoneOverride__c = '92345678';
        secondResource.HOT_ServiceTerritory__c = territory.Id;
        insert new List<ServiceResource>{ firstResource, secondResource };
        insert new List<ServiceTerritoryMember>{
            HOT_TestDataFactory.createServiceTerritoryMember(firstResource, territory),
            HOT_TestDataFactory.createServiceTerritoryMember(secondResource, territory)
        };

        List<ServiceAppointment> firstAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :firstRequest.Id
            ORDER BY EarliestStartTime, Id
        ];
        ServiceAppointment secondAppointment = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :secondRequest.Id
            LIMIT 1
        ];
        insert new List<AssignedResource>{
            HOT_TestDataFactory.createAssignedResource(firstAppointments[0].Id, firstResource.Id),
            HOT_TestDataFactory.createAssignedResource(firstAppointments[1].Id, secondResource.Id),
            HOT_TestDataFactory.createAssignedResource(secondAppointment.Id, firstResource.Id)
        };
    }

    @IsTest
    static void findsAllAssignedInterpretersForRequest() {
        ServiceAppointment appointment = getFirstAppointment();
        List<AssignedResource> resources = HOT_ServiceAppointmentMessageHandler.getAssignedResources(
            new List<HOT_ServiceAppointmentMessage__c>{
                new HOT_ServiceAppointmentMessage__c(Request__c = appointment.HOT_Request__c)
            }
        );

        Assert.areEqual(2, resources.size());
        Set<Id> users = new Set<Id>();
        for (AssignedResource resource : resources) {
            Assert.areEqual(appointment.HOT_Request__c, resource.ServiceAppointment.HOT_Request__c);
            users.add(resource.ServiceResource.RelatedRecordId);
        }
        Assert.areEqual(2, users.size());
    }

    @IsTest
    static void findsAssignedInterpretersForWorkOrder() {
        ServiceAppointment appointment = getFirstAppointment();
        List<AssignedResource> resources = HOT_ServiceAppointmentMessageHandler.getAssignedResources(
            new List<HOT_ServiceAppointmentMessage__c>{
                new HOT_ServiceAppointmentMessage__c(WorkOrder__c = appointment.HOT_WorkOrderID__c)
            }
        );

        Assert.areEqual(2, resources.size());
        for (AssignedResource resource : resources) {
            Assert.areEqual(appointment.HOT_WorkOrderID__c, resource.ServiceAppointment.HOT_WorkOrderID__c);
        }
    }

    @IsTest
    static void handlesMixedMessagesWithOneQuery() {
        ServiceAppointment firstAppointment = getFirstAppointment();
        ServiceAppointment secondAppointment = [
            SELECT Id, HOT_WorkOrderID__c
            FROM ServiceAppointment
            WHERE HOT_Request__c != :firstAppointment.HOT_Request__c
            LIMIT 1
        ];
        List<HOT_ServiceAppointmentMessage__c> messages = new List<HOT_ServiceAppointmentMessage__c>{
            new HOT_ServiceAppointmentMessage__c(Request__c = firstAppointment.HOT_Request__c),
            new HOT_ServiceAppointmentMessage__c(WorkOrder__c = secondAppointment.HOT_WorkOrderID__c)
        };

        Test.startTest();
        List<AssignedResource> resources = HOT_ServiceAppointmentMessageHandler.getAssignedResources(messages);
        Assert.areEqual(1, Limits.getQueries());
        Test.stopTest();

        Assert.areEqual(3, resources.size());
    }

    @IsTest
    static void ignoresMessagesWithoutEitherLookup() {
        Test.startTest();
        List<AssignedResource> resources = HOT_ServiceAppointmentMessageHandler.getAssignedResources(
            new List<HOT_ServiceAppointmentMessage__c>{ new HOT_ServiceAppointmentMessage__c() }
        );
        HOT_ServiceAppointmentMessageHandler handler = new HOT_ServiceAppointmentMessageHandler();
        handler.doConstruct(new List<HOT_ServiceAppointmentMessage__c>{ new HOT_ServiceAppointmentMessage__c() });
        handler.onAfterInsert();
        Assert.areEqual(0, Limits.getQueries());
        Test.stopTest();

        Assert.areEqual(0, resources.size());
    }

    @IsTest
    static void forwardsMessagesForAssignedAppointments() {
        ServiceAppointment appointment = getFirstAppointment();
        Map<Id, Id> serviceAppointmentsByResource = getServiceAppointmentsByResource(appointment.HOT_Request__c);

        Test.startTest();
        HOT_ServiceAppointmentMessageHandler handler = new HOT_ServiceAppointmentMessageHandler();
        handler.doConstruct(
            new List<HOT_ServiceAppointmentMessage__c>{
                new HOT_ServiceAppointmentMessage__c(Message__c = 'Beskjed uten tilknyttet oppdrag'),
                new HOT_ServiceAppointmentMessage__c(
                    Request__c = appointment.HOT_Request__c,
                    Message__c = 'Beskjed til tildelte tolker'
                ),
                new HOT_ServiceAppointmentMessage__c(
                    WorkOrder__c = appointment.HOT_WorkOrderID__c,
                    Message__c = 'Beskjed om arbeidsordren'
                )
            }
        );
        handler.onAfterInsert();
        Test.stopTest();

        List<HOT_Notification__c> notifications = getMessageNotifications();
        Assert.areEqual(4, notifications.size(), 'Separate messages must not be collapsed into one notification');
        for (HOT_Notification__c notification : notifications) {
            assertNotification(
                notification,
                serviceAppointmentsByResource.get(notification.HOT_ServiceResource__c),
                'Push-varsel i appen',
                messageText()
            );
        }
        Assert.areEqual(0, [SELECT COUNT() FROM SMS__c WHERE ServiceAppointment__c = :appointment.Id]);
    }

    @IsTest
    static void routesByChannelIncludingEmployedSMS() {
        ServiceAppointment appointment = getFirstAppointment();
        Map<Id, Id> serviceAppointmentsByResource = getServiceAppointmentsByResource(appointment.HOT_Request__c);
        ServiceResource smsResource = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
            LIMIT 1
        ];
        smsResource.HOT_NotificationChannel__c = 'SMS';
        smsResource.HOT_IsEmployedInterpreter__c = true;
        smsResource.HOT_IsFreelanceInterpreter__c = false;
        update smsResource;

        Test.startTest();
        HOT_ServiceAppointmentMessageHandler.notifyAssignedInterpreters(
            new List<HOT_ServiceAppointmentMessage__c>{
                new HOT_ServiceAppointmentMessage__c(Request__c = appointment.HOT_Request__c)
            }
        );
        Test.stopTest();

        List<HOT_Notification__c> notifications = getMessageNotifications();
        Assert.areEqual(2, notifications.size());
        for (HOT_Notification__c notification : notifications) {
            Boolean isSMS = notification.HOT_ServiceResource__c == smsResource.Id;
            assertNotification(
                notification,
                serviceAppointmentsByResource.get(notification.HOT_ServiceResource__c),
                isSMS ? 'SMS' : 'Push-varsel i appen',
                isSMS ? smsText() : messageText()
            );
        }
        List<SMS__c> smsMessages = [
            SELECT Domain__c, Type__c, ServiceAppointment__c, Recipient__c, Message__c
            FROM SMS__c
            WHERE ServiceAppointment__c = :appointment.Id
        ];
        Assert.areEqual(1, smsMessages.size());
        Assert.areEqual(smsText(), smsMessages[0].Message__c);
        Assert.areEqual('91234567', smsMessages[0].Recipient__c);
        Assert.areEqual('HOT', smsMessages[0].Domain__c);
        Assert.areEqual('Interpreter', smsMessages[0].Type__c);
    }

    @IsTest
    static void retainsSMSNotificationsWithoutPhone() {
        ServiceAppointment appointment = getFirstAppointment();
        Map<Id, Id> serviceAppointmentsByResource = getServiceAppointmentsByResource(appointment.HOT_Request__c);
        List<ServiceResource> resources = [SELECT Id FROM ServiceResource];
        for (ServiceResource resource : resources) {
            resource.HOT_NotificationChannel__c = 'SMS';
            resource.HOT_MobilePhoneOverride__c = null;
        }
        update resources;

        Test.startTest();
        HOT_ServiceAppointmentMessageHandler.notifyAssignedInterpreters(
            new List<HOT_ServiceAppointmentMessage__c>{
                new HOT_ServiceAppointmentMessage__c(WorkOrder__c = appointment.HOT_WorkOrderID__c)
            }
        );
        Test.stopTest();

        List<HOT_Notification__c> notifications = getMessageNotifications();
        Assert.areEqual(2, notifications.size());
        for (HOT_Notification__c notification : notifications) {
            assertNotification(
                notification,
                serviceAppointmentsByResource.get(notification.HOT_ServiceResource__c),
                'SMS',
                smsText()
            );
        }
        Assert.areEqual(0, [SELECT COUNT() FROM SMS__c WHERE ServiceAppointment__c = :appointment.Id]);
    }

    @IsTest
    static void retainsPushNotificationsWithoutUser() {
        ServiceAppointment appointment = getFirstAppointment();
        List<HOT_ServiceAppointmentMessage__c> messages = new List<HOT_ServiceAppointmentMessage__c>{
            new HOT_ServiceAppointmentMessage__c(Request__c = appointment.HOT_Request__c)
        };
        List<AssignedResource> assignedResources = HOT_ServiceAppointmentMessageHandler.getAssignedResources(messages);
        for (AssignedResource assignedResource : assignedResources) {
            assignedResource.ServiceResource.RelatedRecordId = null;
        }

        Test.startTest();
        HOT_ServiceAppointmentNotification.newServiceAppointmentMessageNotification(messages, assignedResources);
        Test.stopTest();

        Assert.areEqual(2, getMessageNotifications().size());
        Assert.areEqual(0, [SELECT COUNT() FROM SMS__c WHERE ServiceAppointment__c = :appointment.Id]);
    }

    @IsTest
    static void deduplicatesAssignmentsButNotMessages() {
        ServiceAppointment appointment = getFirstAppointment();
        List<ServiceResource> resources = [SELECT Id FROM ServiceResource];
        for (ServiceResource resource : resources) {
            resource.HOT_NotificationChannel__c = 'SMS';
        }
        update resources;
        List<HOT_ServiceAppointmentMessage__c> messages = new List<HOT_ServiceAppointmentMessage__c>{
            new HOT_ServiceAppointmentMessage__c(
                Request__c = appointment.HOT_Request__c,
                WorkOrder__c = appointment.HOT_WorkOrderID__c
            ),
            new HOT_ServiceAppointmentMessage__c(WorkOrder__c = appointment.HOT_WorkOrderID__c)
        };
        List<AssignedResource> assignedResources = HOT_ServiceAppointmentMessageHandler.getAssignedResources(messages);
        assignedResources.add(assignedResources[0]);
        for (AssignedResource assignedResource : assignedResources) {
            assignedResource.ServiceResource.RelatedRecordId = null;
        }

        Test.startTest();
        HOT_ServiceAppointmentNotification.newServiceAppointmentMessageNotification(messages, assignedResources);
        Test.stopTest();

        Assert.areEqual(4, getMessageNotifications().size());
        Assert.areEqual(
            4,
            [SELECT COUNT() FROM SMS__c WHERE ServiceAppointment__r.HOT_Request__c = :appointment.HOT_Request__c]
        );
    }

    @IsTest
    static void handlesBulkSMSMessages() {
        ServiceAppointment appointment = getFirstAppointment();
        List<ServiceResource> resources = [SELECT Id FROM ServiceResource];
        for (ServiceResource resource : resources) {
            resource.HOT_NotificationChannel__c = 'SMS';
        }
        update resources;
        List<HOT_ServiceAppointmentMessage__c> messages = new List<HOT_ServiceAppointmentMessage__c>();
        for (Integer i = 0; i < 200; i++) {
            messages.add(new HOT_ServiceAppointmentMessage__c(Request__c = appointment.HOT_Request__c));
        }

        Test.startTest();
        HOT_ServiceAppointmentMessageHandler.notifyAssignedInterpreters(messages);
        Test.stopTest();

        Assert.areEqual(400, getMessageNotifications().size());
        Assert.areEqual(
            400,
            [SELECT COUNT() FROM SMS__c WHERE ServiceAppointment__r.HOT_Request__c = :appointment.HOT_Request__c]
        );
    }

    private static Map<Id, Id> getServiceAppointmentsByResource(Id requestId) {
        Map<Id, Id> serviceAppointmentsByResource = new Map<Id, Id>();
        for (AssignedResource assignedResource : [
            SELECT ServiceResourceId, ServiceAppointmentId
            FROM AssignedResource
            WHERE ServiceAppointment.HOT_Request__c = :requestId
        ]) {
            serviceAppointmentsByResource.put(
                assignedResource.ServiceResourceId,
                assignedResource.ServiceAppointmentId
            );
        }
        Assert.areEqual(2, serviceAppointmentsByResource.size());
        Assert.areEqual(2, new Set<Id>(serviceAppointmentsByResource.values()).size());
        return serviceAppointmentsByResource;
    }

    private static String messageText() {
        return 'Formidler har gitt deg en beskjed angående et oppdrag du er tildelt.';
    }

    private static String smsText() {
        return messageText() +
            '\n\nFor mer informasjon, se tolkebestilling.nav.no. Du kan ikke svare på denne meldingen.' +
            '\nMvh tolketjenesten i Nav';
    }

    private static List<HOT_Notification__c> getMessageNotifications() {
        return [
            SELECT
                HOT_ServiceResource__c,
                HOT_NotificationChannel__c,
                HOT_Subject__c,
                HOT_NotificationText__c,
                HOT_RelatedObject__c,
                HOT_RelatedObjectType__c
            FROM HOT_Notification__c
            WHERE HOT_Subject__c = 'Ny beskjed fra formidler'
        ];
    }

    private static void assertNotification(
        HOT_Notification__c notification,
        Id serviceAppointmentId,
        String channel,
        String text
    ) {
        Assert.isNotNull(notification.HOT_ServiceResource__c);
        Assert.areEqual('Ny beskjed fra formidler', notification.HOT_Subject__c);
        Assert.areEqual(String.valueOf(serviceAppointmentId), notification.HOT_RelatedObject__c);
        Assert.areEqual('serviceAppointment', notification.HOT_RelatedObjectType__c);
        Assert.areEqual(channel, notification.HOT_NotificationChannel__c);
        Assert.areEqual(text, notification.HOT_NotificationText__c);
        Assert.isTrue(text.length() <= 255);
    }

    private static ServiceAppointment getFirstAppointment() {
        return [
            SELECT Id, HOT_Request__c, HOT_WorkOrderID__c
            FROM ServiceAppointment
            ORDER BY EarliestStartTime, Id
            LIMIT 1
        ];
    }
}
