@IsTest
private class HOT_SAOwnerGroupNotificationTest {
    private class NotificationTestException extends Exception {
    }

    private class StubNotificationSender extends HOT_SAOwnerGroupNotificationService.NotificationSender {
        Integer sendCount = 0;
        Boolean failSend = false;

        public override void send(Messaging.CustomNotification notification, Set<String> recipients) {
            sendCount++;
            if (failSend) {
                throw new NotificationTestException('Expected send failure.');
            }
        }
    }

    @IsTest
    static void serviceReturnsSentForOwnerDerivedFormidlerGroup() {
        Group queue = createOwnerQueueAndFormidlerGroup('999001');
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.OwnerId = queue.Id;
        insert serviceAppointment;

        StubNotificationSender sender = new StubNotificationSender();
        HOT_SAOwnerGroupNotificationService service = new HOT_SAOwnerGroupNotificationService(sender);

        List<HOT_SAOwnerGroupNotification.Result> results = service.process(
            new List<HOT_SAOwnerGroupNotification.WorkItem>{ createWorkItem(serviceAppointment.Id) }
        );

        System.assertEquals(1, results.size());
        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_SENT, results[0].status);
        System.assertEquals(true, results[0].sent);
        System.assertEquals(1, sender.sendCount);
    }

    @IsTest
    static void invocableQueuesValidRequest() {
        Group queue = createOwnerQueueAndFormidlerGroup('999002');
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.OwnerId = queue.Id;
        insert serviceAppointment;

        HOT_SAOwnerGroupNotification.Request request = createRequest(serviceAppointment.Id);

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> results = HOT_SAOwnerGroupNotification.send(
            new List<HOT_SAOwnerGroupNotification.Request>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_QUEUED, results[0].status);
        System.assertEquals(true, results[0].queued);
    }

    @IsTest
    static void serviceReturnsMissingRecipientWithoutThrowing() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        insert serviceAppointment;

        StubNotificationSender sender = new StubNotificationSender();
        HOT_SAOwnerGroupNotificationService service = new HOT_SAOwnerGroupNotificationService(sender);

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> results = service.process(
            new List<HOT_SAOwnerGroupNotification.WorkItem>{ createWorkItem(serviceAppointment.Id) }
        );
        Test.stopTest();

        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_MISSING_RECIPIENT, results[0].status);
        System.assertEquals(true, results[0].missingRecipient);
        System.assertEquals(0, sender.sendCount);
    }

    @IsTest
    static void serviceReturnsFailedWhenSenderThrows() {
        Group queue = createOwnerQueueAndFormidlerGroup('999003');
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.OwnerId = queue.Id;
        insert serviceAppointment;

        StubNotificationSender sender = new StubNotificationSender();
        sender.failSend = true;
        HOT_SAOwnerGroupNotificationService service = new HOT_SAOwnerGroupNotificationService(sender);

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> results = service.process(
            new List<HOT_SAOwnerGroupNotification.WorkItem>{ createWorkItem(serviceAppointment.Id) }
        );
        Test.stopTest();

        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_FAILED, results[0].status);
        System.assertEquals('Expected send failure.', results[0].message);
        System.assertEquals(1, sender.sendCount);
    }

    @IsTest
    static void invalidAndDuplicateRequestsAreSkippedInInputOrder() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        insert serviceAppointment;

        HOT_SAOwnerGroupNotification.Request validRequest = createRequest(serviceAppointment.Id);
        HOT_SAOwnerGroupNotification.Request duplicateRequest = createRequest(serviceAppointment.Id);
        HOT_SAOwnerGroupNotification.Request invalidRequest = new HOT_SAOwnerGroupNotification.Request();

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> results = HOT_SAOwnerGroupNotification.send(
            new List<HOT_SAOwnerGroupNotification.Request>{ validRequest, duplicateRequest, invalidRequest }
        );
        Test.stopTest();

        System.assertEquals(3, results.size());
        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_QUEUED, results[0].status);
        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_SKIPPED, results[1].status);
        System.assertEquals('Duplicate notification request.', results[1].message);
        System.assertEquals(HOT_SAOwnerGroupNotification.STATUS_SKIPPED, results[2].status);
    }

    @IsTest
    static void queueableSplitsWorkIntoBoundedChunks() {
        List<HOT_SAOwnerGroupNotification.WorkItem> workItems = new List<HOT_SAOwnerGroupNotification.WorkItem>();
        for (Integer index = 0; index < 11; index++) {
            workItems.add(createWorkItem(UserInfo.getUserId()));
        }

        System.assertEquals(10, HOT_SAOwnerGroupNotificationQueueable.firstChunk(workItems).size());
        System.assertEquals(1, HOT_SAOwnerGroupNotificationQueueable.remainingItems(workItems).size());
        System.assertEquals(0, HOT_SAOwnerGroupNotificationQueueable.firstChunk(null).size());
    }

    @IsTest
    static void invocableHandlesNullAndEmptyCollections() {
        System.assertEquals(0, HOT_SAOwnerGroupNotification.send(null).size());
        System.assertEquals(
            0,
            HOT_SAOwnerGroupNotification.send(new List<HOT_SAOwnerGroupNotification.Request>()).size()
        );
    }

    private static HOT_SAOwnerGroupNotification.Request createRequest(Id serviceAppointmentId) {
        HOT_SAOwnerGroupNotification.Request request = new HOT_SAOwnerGroupNotification.Request();
        request.serviceAppointmentId = serviceAppointmentId;
        request.title = 'Tjenesteleverandør';
        request.body = 'Oppdraget krever oppfølging.';
        return request;
    }

    private static HOT_SAOwnerGroupNotification.WorkItem createWorkItem(Id serviceAppointmentId) {
        HOT_SAOwnerGroupNotification.WorkItem workItem = new HOT_SAOwnerGroupNotification.WorkItem();
        workItem.serviceAppointmentId = serviceAppointmentId;
        workItem.title = 'Tjenesteleverandør';
        workItem.body = 'Oppdraget krever oppfølging.';
        return workItem;
    }

    private static Group createOwnerQueueAndFormidlerGroup(String region) {
        Group formidlerGroup = new Group(
            Name = 'HOT group ' + region + ' formidler',
            DeveloperName = 'HOT_group_' + region + '_formidler',
            Type = 'Regular'
        );
        Group queue = new Group(Name = 'Queue ' + region, DeveloperName = 'queue_' + region, Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<Group>{ formidlerGroup, queue };
            insert new QueueSobject(QueueID = queue.Id, SobjectType = 'ServiceAppointment');
        }
        return queue;
    }

    private static ServiceAppointment createServiceAppointment() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('supplier notification', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        return HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
    }
}
