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
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert new List<User>{ user, user2 };
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsEmployedInterpreter__c = false;
        serviceResource.HOT_MobilePhoneOverride__c = '12345678';
        serviceResource.HOT_IsFreelanceInterpreter__c = true;

        ServiceResource serviceResource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        serviceResource2.HOT_IsEmployedInterpreter__c = true;
        insert new List<ServiceResource>{ serviceResource, serviceResource2 };

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        ServiceTerritoryMember serviceTerritoryMember2 = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource2,
            serviceTerritory
        );
        insert new List<ServiceTerritoryMember>{ serviceTerritoryMember, serviceTerritoryMember2 };

        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Name = 'Test1';
        resource.Service_Resource__c = serviceResource.Id;
        HOT_Resource__c resource2 = new HOT_Resource__c();
        resource2.Name = 'Test2';
        resource2.Service_Resource__c = serviceResource2.Id;
        insert new List<HOT_Resource__c>{ resource, resource2 };

        HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
        resourceMember.Resource__c = resource.Id;
        resourceMember.Service_Resource__c = serviceResource.Id;
        HOT_ResourceMember__c resourceMember2 = new HOT_ResourceMember__c();
        resourceMember2.Resource__c = resource2.Id;
        resourceMember2.Service_Resource__c = serviceResource2.Id;
        insert new List<HOT_ResourceMember__c>{ resourceMember, resourceMember2 };

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
    private static void resourceCanceledNotifiesTLDispatcherTest() {
        verifyNotificationRecipients(true, false, false);
    }

    @IsTest
    private static void resourceCanceledNotifiesProviderGroupTest() {
        verifyNotificationRecipients(true, true, false);
    }

    @IsTest
    private static void canceledByUserNotifiesTLDispatcherTest() {
        verifyNotificationRecipients(false, false, false);
    }

    @IsTest
    private static void canceledByUserNotifiesProviderGroupTest() {
        verifyNotificationRecipients(false, true, false);
    }

    @IsTest
    private static void resourceCanceledDispatcherCreatesNoRecordsTest() {
        verifyNotificationRecipients(true, false, true);
    }

    @IsTest
    private static void canceledByUserDispatcherCreatesNoRecordsTest() {
        verifyNotificationRecipients(false, false, true);
    }

    private static void verifyNotificationRecipients(
        Boolean resourceCanceled,
        Boolean useGroup,
        Boolean isEmployedInterpreter
    ) {
        List<ServiceResource> resources = [
            SELECT Id, Name, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId != NULL
            ORDER BY Name
        ];
        Set<Id> expectedRecipients = new Set<Id>{ resources[0].RelatedRecordId };
        if (useGroup) {
            expectedRecipients.add(resources[1].RelatedRecordId);
            System.runAs(new User(Id = UserInfo.getUserId())) {
                Group providerGroup = [
                    SELECT Id
                    FROM Group
                    WHERE DeveloperName = 'HOT_Tolk_Tjenesteleverandor' AND Type = 'Regular'
                ];
                delete [SELECT Id FROM GroupMember WHERE GroupId = :providerGroup.Id];
                insert new List<GroupMember>{
                    new GroupMember(GroupId = providerGroup.Id, UserOrGroupId = resources[0].RelatedRecordId),
                    new GroupMember(GroupId = providerGroup.Id, UserOrGroupId = resources[1].RelatedRecordId)
                };
            }
        }
        ServiceAppointment appointment = [
            SELECT
                Id,
                OwnerId,
                AppointmentNumber,
                Subject,
                EarliestStartTime,
                Status,
                HOT_WorkOrderLineItem__c,
                HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__c,
                HOT_CanceledByInterpreter__c,
                HOT_TLDispatcher__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        appointment.HOT_IsEmployedInterpreter__c = isEmployedInterpreter;
        appointment.HOT_ServiceResource__c = resources[0].Id;
        ServiceAppointment oldAppointment = appointment.clone(true, false, false, false);
        oldAppointment.HOT_ServiceResource__c = resources[0].Id;
        oldAppointment.HOT_CanceledByInterpreter__c = false;
        oldAppointment.Status = 'Dispatched';
        appointment.HOT_TLDispatcher__c = useGroup ? null : resources[0].RelatedRecordId;
        appointment.HOT_CanceledByInterpreter__c = resourceCanceled;
        appointment.Status = resourceCanceled ? 'Dispatched' : 'Canceled';
        Integer notificationCountBefore = [SELECT COUNT() FROM HOT_Notification__c];

        Test.startTest();
        HOT_ServiceAppointmentNotification.dispatcherServiceAppointmentChanged(
            new List<ServiceAppointment>{ appointment },
            new Map<Id, SObject>{ appointment.Id => oldAppointment }
        );
        Test.stopTest();

        if (isEmployedInterpreter) {
            System.assertEquals(
                notificationCountBefore,
                [SELECT COUNT() FROM HOT_Notification__c],
                'Dispatcher notifications must not create HOT_Notification__c records'
            );
            return;
        }

        List<HOT_Notification__c> notifications = [
            SELECT Tjenesteleverandor__c, HOT_Subject__c, HOT_NotificationText__c, HOT_RelatedObjectType__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :appointment.Id AND Tjenesteleverandor__c != NULL
        ];
        System.assertEquals(expectedRecipients.size(), notifications.size());
        Set<Id> actualRecipients = new Set<Id>();
        for (HOT_Notification__c notification : notifications) {
            actualRecipients.add(notification.Tjenesteleverandor__c);
            System.assertEquals('serviceAppointment', notification.HOT_RelatedObjectType__c);
            System.assertEquals(
                resourceCanceled
                    ? 'Tolk tar seg av: \n' + appointment.AppointmentNumber
                    : appointment.AppointmentNumber +
                      ' - ' +
                      appointment.EarliestStartTime?.format('d.M.yyyy') +
                      ' -  Avlyst',
                notification.HOT_Subject__c
            );
            System.assert(
                notification.HOT_NotificationText__c.contains(
                    resourceCanceled ? resources[0].Name + ' meldte seg av' : 'er avlyst.'
                )
            );
        }
        System.assertEquals(expectedRecipients, actualRecipients);
    }

    @IsTest
    private static void notifyResourceAndDispatcherTest() {
        List<ServiceResource> testResources = [
            SELECT Id, HOT_IsEmployedInterpreter__c
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
        ];

        //AR på SA
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        Test.startTest();

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

        if (testResources.size() > 1) {
            assignedResource = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, testResources[1].Id);
            insert assignedResource;
            serviceAppointment.HOT_AssignedResourceId__c = assignedResource.Id;
            update serviceAppointment;
        }

        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
            LIMIT 1
        ];

        //Tolk tar seg av
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

        //endring av skjermtolk/oppmøtetolk
        serviceAppointment.HOT_IsNotifyDispatcher__c = true;
        serviceAppointment.Status = 'Dispatched';
        serviceAppointment.HOT_IsScreenInterpreterNew__c = true;
        serviceAppointment.PostalCode = '3044';
        update serviceAppointment;

        //Avlyst på vegne av bruker
        serviceAppointment.HOT_IsNotifyDispatcher__c = true;
        serviceAppointment.Status = 'Canceled';
        update serviceAppointment;

        Test.stopTest();

        serviceAppointment = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :serviceAppointment.Id LIMIT 1];

        system.assertEquals('Canceled', serviceAppointment.Status, 'Could not set Status');
    }

    @IsTest
    private static void canceledByUserTest() {
        ServiceAppointment sa = [
            SELECT Id, AppointmentNumber, EarliestStartTime
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();

        sa.Status = 'Canceled';

        update sa;

        Test.stopTest();
        List<HOT_Notification__c> notifications = [SELECT Id, HOT_NotificationText__c FROM HOT_Notification__c];
        System.assertEquals(1, notifications.size(), 'There should be one notification record after status change');
    }

    @IsTest
    private static void canceledByUserSMSTest() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c WHERE PreferredResource1__r.Name = 'Test1' LIMIT 1];
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        serviceResource.HOT_NotificationChannel__c = 'SMS';
        update serviceResource;
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c = :request.Id LIMIT 1];

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records before test starts');
        Test.startTest();
        sa.Status = 'Canceled';
        update sa;
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM SMS__c], 'TThere should be one SMS record after test');
    }

    @IsTest
    private static void timeChangedTest() {
        ServiceAppointment sa = [
            SELECT Id, HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        DateTime now = DateTime.now();
        DateTime newTime = now.addDays(2);
        DateTime newTime2 = newTime.addHours(2);
        sa.EarliestStartTime = newTime;
        sa.DueDate = newTime2;
        update sa;
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records before test starts');

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        Test.startTest();

        now = DateTime.now();
        newTime = now.addDays(3);
        newTime2 = newTime.addHours(3);
        sa.EarliestStartTime = newTime;
        sa.DueDate = newTime2;
        update sa;
        Test.stopTest();
        System.assertEquals(
            1,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be one notification record after time change'
        );
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records after time change');
    }
    @IsTest
    private static void timeChangedSMSTest() {
        ServiceAppointment sa = [
            SELECT Id, HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        DateTime now = DateTime.now();
        DateTime newTime = now.addDays(2);
        DateTime newTime2 = newTime.addHours(2);
        sa.EarliestStartTime = newTime;
        sa.DueDate = newTime2;
        update sa;

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        serviceResource.HOT_NotificationChannel__c = 'SMS';
        update serviceResource;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records before test starts');

        Test.startTest();

        now = DateTime.now();
        newTime = now.addDays(3);
        newTime2 = newTime.addHours(3);
        sa.EarliestStartTime = newTime;
        sa.DueDate = newTime2;
        update sa;

        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be one notification record after time change'
        );
        System.assertEquals(1, [SELECT COUNT() FROM SMS__c], 'There should be one SMS records after time change');
    }

    @IsTest
    private static void addressChangedTest() {
        ServiceAppointment sa = [
            SELECT Id, HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        sa.Status = 'Dispatched';
        update sa;

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records before test starts');

        Test.startTest();

        sa.Street = 'Tolkeveien 123';
        update sa;
        Test.stopTest();
        List<HOT_Notification__c> notifications = [SELECT Id, HOT_NotificationText__c FROM HOT_Notification__c];
        System.assertEquals(1, notifications.size(), 'There should be one notification record after time change');
        System.assert(
            notifications[0].HOT_NotificationText__c.startsWith('Ny adresse er'),
            'Notification text is incorrect'
        );
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records after time change');
    }

    @IsTest
    private static void addressChangedSMSTest() {
        ServiceAppointment sa = [
            SELECT Id, HOT_ServiceResource__r.HOT_NotificationChannel__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        sa.Status = 'Dispatched';
        update sa;

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        serviceResource.HOT_NotificationChannel__c = 'SMS';
        update serviceResource;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c], 'There should be no SMS records before test starts');

        Test.startTest();

        sa.Street = 'Tolkeveien 123';
        update sa;
        Test.stopTest();
        List<HOT_Notification__c> notifications = [SELECT Id, HOT_Subject__c FROM HOT_Notification__c];
        System.assertEquals(1, notifications.size(), 'There should be one notification record after address change');
        System.assert(notifications[0].HOT_Subject__c.contains('har endret adresse'), 'Notification text is incorrect');
        List<SMS__c> smss = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(1, smss.size(), 'There should be no SMS records after address change');
        System.assert(smss[0].Message__c.contains('har endret adresse'), 'SMS text is incorrect');
    }

    @IsTest
    private static void notifyInterpretersOnChangedResourceTest() {
        ServiceAppointment sa = [
            SELECT
                Id,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_AssignedResourceId__c,
                HOT_WorkOrderLineItem__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource freelanceResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        ServiceResource employeeResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
            LIMIT 1
        ];

        HOT_Request__c request = [
            SELECT Id, Orderer__c
            FROM HOT_Request__c
            WHERE PreferredResource1__r.Name = 'Test1'
            LIMIT 1
        ];

        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :sa.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];

        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa2.HOT_Request__c = request.Id;
        sa2.Subject = 'Flertolksoppdrag med endring av medtolk';
        insert sa2;

        myTriggers.disable(HOT_ServiceAppointmentHandler.class);

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa.Id, freelanceResource.Id));
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa2.Id, employeeResource.Id));
        insert assignedResources;

        sa.Status = 'Dispatched';
        sa2.Status = 'Dispatched';

        update new List<ServiceAppointment>{ sa, sa2 };

        myTriggers.enable(HOT_ServiceAppointmentHandler.class);
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();

        sa.HOT_ServiceResource__c = employeeResource.Id;
        sa.HOT_AssignedResourceId__c = employeeResource.RelatedRecordId;

        update new List<ServiceAppointment>{ sa, sa2 };

        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_Subject__c, HOT_NotificationText__c
            FROM HOT_Notification__c
        ];
        System.assertEquals(2, notifications.size(), 'There should be 2 notification records after resource change');
        System.assert(
            notifications[0].HOT_Subject__c.startsWith('Du er tildelt oppdraget'),
            'Expected assing notification'
        );
        System.assert(notifications[1].HOT_Subject__c.startsWith('Endring av medtolk'), 'Expected change notification');
    }

    @IsTest
    private static void notifyInterpretersOnChangedResourceSMSTest() {
        ServiceAppointment sa = [
            SELECT
                Id,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_AssignedResourceId__c,
                HOT_WorkOrderLineItem__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource freelanceResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];
        ServiceResource employeeResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = TRUE
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        myTriggers.disable(HOT_ServiceResourceHandler.class);
        freelanceResource.HOT_NotificationChannel__c = 'SMS';
        freelanceResource.AccountId = acc.id;
        employeeResource.HOT_NotificationChannel__c = 'SMS';
        employeeResource.AccountId = acc.id;
        update new List<ServiceResource>{ freelanceResource, employeeResource };

        HOT_Request__c request = [
            SELECT Id, Orderer__c
            FROM HOT_Request__c
            WHERE PreferredResource1__r.Name = 'Test1'
            LIMIT 1
        ];

        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :sa.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];

        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa2.HOT_Request__c = request.Id;
        sa2.Subject = 'Flertolksoppdrag med endring av medtolk';
        insert sa2;

        myTriggers.disable(HOT_ServiceAppointmentHandler.class);

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa.Id, freelanceResource.Id));
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa2.Id, freelanceResource.Id));
        insert assignedResources;

        sa.Status = 'Dispatched';
        sa2.Status = 'Dispatched';

        update new List<ServiceAppointment>{ sa, sa2 };

        myTriggers.enable(HOT_ServiceAppointmentHandler.class);
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();

        sa2.HOT_ServiceResource__c = employeeResource.Id;
        sa2.HOT_AssignedResourceId__c = employeeResource.RelatedRecordId;

        update new List<ServiceAppointment>{ sa, sa2 };

        Test.stopTest();
        List<SMS__c> smss = [SELECT Id, Message__c FROM SMS__c];
        System.assertEquals(2, smss.size(), 'There should be 2 SMS records after resource change');
        System.assert(smss[0].Message__c.startsWith('INFO\nDu er tildelt oppdraget'), 'Expexting assing SMS');
        System.assert(
            smss[1].Message__c.startsWith('INFO\nMedtolk på et oppdrag du er tildelt er blitt endret'),
            'Expecting change cointerpreter SMS'
        );

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_Subject__c, HOT_NotificationText__c
            FROM HOT_Notification__c
        ];
        System.assertEquals(2, notifications.size(), 'There should be 2 notification records after resource change');
        System.assert(
            notifications[0].HOT_Subject__c.startsWith('INFO\n Du er tildelt oppdraget '),
            'Expected assing notification'
        );
        System.assert(notifications[1].HOT_Subject__c.startsWith('Endring av medtolk'), 'Expected change notification');
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
    private static void notifyInterpretersOnCoInterpreterRemovedTest() {
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
        ServiceAppointment sa = [
            SELECT
                Id,
                HOT_WorkOrderLineItem__c,
                DueDate,
                AccountId,
                SchedEndTime,
                SchedStartTime,
                AppointmentNumber,
                EarliestStartTime,
                HOT_AddressFormated__c,
                HOT_Request__r.Orderer__c,
                HOT_AssignedResourceId__c,
                HOT_ServiceResource__r.Name,
                HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.AccountId,
                HOT_WorkOrderLineItem__r.WorkOrderId,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        HOT_Request__c request = [
            SELECT Id, Orderer__c
            FROM HOT_Request__c
            WHERE PreferredResource1__r.Name = 'Test1'
            LIMIT 1
        ];

        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :sa.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];

        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa2.HOT_Request__c = request.Id;
        sa2.Subject = 'Flertolksoppdrag med endring av medtolk';
        insert sa2;
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id));
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa2.Id, serviceResourceFreelance.Id));
        insert assignedResources;

        sa.Status = 'Dispatched';
        sa2.Status = 'Dispatched';

        update new List<ServiceAppointment>{ sa, sa2 };
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        myTriggers.enable(HOT_ServiceAppointmentHandler.class);

        Test.startTest();

        delete assignedResources[0];

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records after cointerpreter removed'
        );
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
        ServiceAppointment sa = [
            SELECT Id, HOT_WorkOrderLineItem__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        HOT_Request__c request = [
            SELECT Id, Orderer__c
            FROM HOT_Request__c
            WHERE PreferredResource1__r.Name = 'Test1'
            LIMIT 1
        ];

        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :sa.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];

        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa2.HOT_Request__c = request.Id;
        sa2.Subject = 'Flertolksoppdrag med endring av medtolk';
        insert sa2;
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id));
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa2.Id, serviceResourceFreelance.Id));
        insert assignedResources;

        sa.Status = 'Dispatched';
        sa2.Status = 'Dispatched';

        update new List<ServiceAppointment>{ sa, sa2 };

        myTriggers.enable(HOT_ServiceAppointmentHandler.class);

        Test.startTest();

        AssignedResource assignedResource = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :sa.Id
            LIMIT 1
        ];
        assignedResource.ServiceResourceId = serviceResourceNew.Id;
        update assignedResource;
        Test.stopTest();
        List<HOT_Notification__c> notifications = [SELECT Id, HOT_Subject__c FROM HOT_Notification__c];
        System.assertEquals(3, notifications.size(), 'There should be 2 notification records after resource change');
        System.assert(notifications[0].HOT_Subject__c.endsWith('Tatt av oppdraget'), 'Expected remove notification');
        System.assert(
            notifications[1].HOT_Subject__c.startsWith('Du er tildelt oppdraget '),
            'Expected assing notification'
        );
        System.assert(notifications[2].HOT_Subject__c.startsWith('Endring av medtolk'), 'Expected change notification');
    }
    @IsTest
    private static void getTargetPageRefInterpreterOnChangedTest() {
        Test.startTest();
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        String result = HOT_ServiceAppointmentNotification.getTargetPageRefInterpreterOnChanged('my', request.Id);
        Test.stopTest();
        System.assertEquals(
            '{type: "comm__namedPage",attributes: {pageName: "mine-oppdrag"}, state: {list: "my", id: "' +
                request.Id +
                '"}}',
            result
        );
    }
    @IsTest
    private static void resourceChangedNullTest() {
        ServiceAppointment sa = [
            SELECT
                Id,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_AssignedResourceId__c,
                HOT_WorkOrderLineItem__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource freelanceResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            LIMIT 1
        ];

        Account acc = [SELECT Id FROM Account LIMIT 1];

        myTriggers.disable(HOT_ServiceResourceHandler.class);
        freelanceResource.HOT_NotificationChannel__c = null;
        freelanceResource.AccountId = acc.id;
        update new List<ServiceResource>{ freelanceResource };
        myTriggers.enable(HOT_ServiceResourceHandler.class);

        myTriggers.disable(HOT_ServiceAppointmentHandler.class);

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        assignedResources.add(HOT_TestDataFactory.createAssignedResource(sa.Id, freelanceResource.Id));
        insert assignedResources;

        sa.Status = 'Dispatched';

        update sa;

        myTriggers.enable(HOT_ServiceAppointmentHandler.class);
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();

        sa.HOT_ServiceResource__c = null;
        sa.HOT_AssignedResourceId__c = null;
        sa.HOT_CanceledByInterpreter__c = false;

        update sa;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be 0 notification records after resource remove'
        );
    }

    @isTest
    private static void notifyInterpretersOnNewFilesTest() {
        ServiceAppointment sa = [
            SELECT
                Id,
                HOT_ServiceResource__r.HOT_NotificationChannel__c,
                HOT_ServiceResource__r.HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__r.RelatedRecordId,
                AppointmentNumber,
                HOT_IsEmployedInterpreter__c,
                HOT_ServiceResource__c,
                HOT_AssignedResourceId__c,
                HOT_WorkOrderLineItem__c
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource serviceResource = [
            SELECT HOT_NotificationChannel__c, HOT_MobilePhoneOverride__c, HOT_IsEmployedInterpreter__c
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = FALSE
            LIMIT 1
        ];
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        serviceResource.HOT_NotificationChannel__c = 'Push-varsel i appen';
        update serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        sa.Status = 'Dispatched';

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();
        HOT_ServiceAppointmentNotification.notifyInterpretersOnNewFiles(new Set<Id>{ sa.Id });
        Test.stopTest();
        List<HOT_Notification__c> notifications = [SELECT Id, HOT_Subject__c FROM HOT_Notification__c];
        System.assertEquals(1, notifications.size(), 'There should be 1 notification record after new file ');
        System.assert(
            notifications[0].HOT_Subject__c.startsWith('Nytt vedlegg er lagt til'),
            'Expected new file notification'
        );
    }

    @IsTest
    private static void screenInterpreterChangedTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
        ServiceResource serviceResource = [
            SELECT HOT_NotificationChannel__c, HOT_MobilePhoneOverride__c, HOT_IsEmployedInterpreter__c
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = FALSE
            LIMIT 1
        ];
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        serviceResource.HOT_NotificationChannel__c = 'Push-varsel i appen';
        update serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();
        sa.HOT_IsScreenInterpreterNew__c = true;
        update sa;
        Test.stopTest();
        List<HOT_Notification__c> notifications = [SELECT Id, HOT_Subject__c FROM HOT_Notification__c];
        System.assertEquals(
            1,
            notifications.size(),
            'There should be 1 notification record after interpreter type change'
        );
        System.assert(
            notifications[0].HOT_Subject__c.endsWith('endret til skjermtolk'),
            'Expected new interpreter type change notification'
        );
    }

    @IsTest
    private static void screenInterpreterChangedNullTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'subject' LIMIT 1];
        ServiceResource serviceResource = [
            SELECT HOT_NotificationChannel__c, HOT_MobilePhoneOverride__c, HOT_IsEmployedInterpreter__c
            FROM ServiceResource
            WHERE HOT_IsEmployedInterpreter__c = FALSE
            LIMIT 1
        ];
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        serviceResource.HOT_NotificationChannel__c = null;
        update serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert assignedResource;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be no notification records before test starts'
        );
        Test.startTest();
        sa.HOT_IsScreenInterpreterNew__c = true;
        update sa;
        Test.stopTest();
        System.assertEquals(
            0,
            [SELECT COUNT() FROM HOT_Notification__c],
            'There should be 0 notification records after interpreter type change'
        );
    }
}
