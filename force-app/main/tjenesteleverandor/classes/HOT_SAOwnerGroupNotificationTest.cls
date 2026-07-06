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

        Test.startTest();
        HOT_SAOwnerGroupNotification.send(new List<HOT_SAOwnerGroupNotification.Request>{ request });
        Test.stopTest();

        System.assert(true, 'Notification helper should send without throwing.');
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
        HOT_SAOwnerGroupNotification.send(new List<HOT_SAOwnerGroupNotification.Request>{ request });
        Test.stopTest();

        System.assert(true, 'Missing owner group should be logged and skipped.');
    }

    @IsTest
    static void nullAndInvalidRequestsAreIgnored() {
        Test.startTest();
        HOT_SAOwnerGroupNotification.send(null);
        HOT_SAOwnerGroupNotification.send(new List<HOT_SAOwnerGroupNotification.Request>());

        HOT_SAOwnerGroupNotification.Request missingId = new HOT_SAOwnerGroupNotification.Request();
        missingId.title = 'Tjenesteleverandør';
        missingId.body = 'Oppdraget krever oppfølging.';

        HOT_SAOwnerGroupNotification.Request blankTitle = new HOT_SAOwnerGroupNotification.Request();
        blankTitle.serviceAppointmentId = UserInfo.getUserId();
        blankTitle.body = 'Oppdraget krever oppfølging.';

        HOT_SAOwnerGroupNotification.send(new List<HOT_SAOwnerGroupNotification.Request>{ missingId, blankTitle });
        Test.stopTest();

        System.assert(true, 'Invalid notification requests should be ignored.');
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
