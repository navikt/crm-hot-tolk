@IsTest
private class HOT_SAOwnerGroupNotificationTest {
    @IsTest
    static void sendsToOwnerDerivedFormidlerGroup() {
        String region = '999001';
        Group formidlerGroup = new Group(
            Name = 'HOT group ' + region + ' formidler',
            DeveloperName = 'HOT_group_' + region + '_formidler',
            Type = 'Regular'
        );
        Group queue = new Group(Name = 'Queue ' + region, DeveloperName = 'queue_' + region, Type = 'Queue');
        insert new List<Group>{ formidlerGroup, queue };
        insert new QueueSobject(QueueID = queue.Id, SobjectType = 'ServiceAppointment');

        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.OwnerId = queue.Id;
        insert serviceAppointment;

        HOT_SAOwnerGroupNotification.Request request = new HOT_SAOwnerGroupNotification.Request();
        request.serviceAppointmentId = serviceAppointment.Id;
        request.title = 'Tjenesteleverandør';
        request.body = 'Oppdraget krever oppfølging.';

        List<HOT_SAOwnerGroupNotification.Result> synchronousResults =
            HOT_SAOwnerGroupNotification.processSynchronously(
                new List<HOT_SAOwnerGroupNotification.Request>{ request }
            );

        System.assertEquals(1, synchronousResults.size());
        System.assertEquals('Sent', synchronousResults[0].status);
        System.assertEquals(true, synchronousResults[0].sent);
        System.assertEquals(false, synchronousResults[0].missingRecipient);

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> queuedResults = HOT_SAOwnerGroupNotification.send(
            new List<HOT_SAOwnerGroupNotification.Request>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, queuedResults.size());
        System.assertEquals('Queued', queuedResults[0].status);
        System.assertEquals(true, queuedResults[0].queued);
    }

    @IsTest
    static void missingOwnerGroupDoesNotThrow() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        insert serviceAppointment;

        HOT_SAOwnerGroupNotification.Request request = new HOT_SAOwnerGroupNotification.Request();
        request.serviceAppointmentId = serviceAppointment.Id;
        request.title = 'Tjenesteleverandør';
        request.body = 'Oppdraget krever oppfølging.';

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> results = HOT_SAOwnerGroupNotification.processSynchronously(
            new List<HOT_SAOwnerGroupNotification.Request>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('MissingRecipient', results[0].status);
        System.assertEquals(true, results[0].missingRecipient);
        System.assertEquals(false, results[0].sent);
    }

    @IsTest
    static void nullAndInvalidRequestsAreIgnored() {
        Test.startTest();
        System.assertEquals(0, HOT_SAOwnerGroupNotification.send(null).size());
        System.assertEquals(0, HOT_SAOwnerGroupNotification.send(new List<HOT_SAOwnerGroupNotification.Request>()).size());

        HOT_SAOwnerGroupNotification.Request missingId = new HOT_SAOwnerGroupNotification.Request();
        missingId.title = 'Tjenesteleverandør';
        missingId.body = 'Oppdraget krever oppfølging.';

        HOT_SAOwnerGroupNotification.Request blankTitle = new HOT_SAOwnerGroupNotification.Request();
        blankTitle.serviceAppointmentId = UserInfo.getUserId();
        blankTitle.body = 'Oppdraget krever oppfølging.';

        List<HOT_SAOwnerGroupNotification.Result> results = HOT_SAOwnerGroupNotification.send(
            new List<HOT_SAOwnerGroupNotification.Request>{ missingId, blankTitle }
        );
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals('Skipped', results[0].status);
        System.assertEquals(true, results[0].skipped);
        System.assertEquals('Skipped', results[1].status);
        System.assertEquals(true, results[1].skipped);
    }

    @IsTest
    static void duplicateRequestsAreSkipped() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        insert serviceAppointment;

        HOT_SAOwnerGroupNotification.Request firstRequest = new HOT_SAOwnerGroupNotification.Request();
        firstRequest.serviceAppointmentId = serviceAppointment.Id;
        firstRequest.title = 'Tjenesteleverandør';
        firstRequest.body = 'Oppdraget krever oppfølging.';

        HOT_SAOwnerGroupNotification.Request duplicateRequest = new HOT_SAOwnerGroupNotification.Request();
        duplicateRequest.serviceAppointmentId = serviceAppointment.Id;
        duplicateRequest.title = 'Tjenesteleverandør';
        duplicateRequest.body = 'Oppdraget krever oppfølging.';

        Test.startTest();
        List<HOT_SAOwnerGroupNotification.Result> results = HOT_SAOwnerGroupNotification.send(
            new List<HOT_SAOwnerGroupNotification.Request>{ firstRequest, duplicateRequest }
        );
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals('Queued', results[0].status);
        System.assertEquals('Skipped', results[1].status);
        System.assertEquals('Duplicate notification request.', results[1].message);
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
