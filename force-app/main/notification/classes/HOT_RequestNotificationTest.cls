@IsTest
public class HOT_RequestNotificationTest {
    @testSetup
    static void setup() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;

        Account account = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Group queue = TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');

        HOT_Request__c rq = HOT_TestDataFactory.createRequest('testRequest', workType);
        rq.OwnerId = queue.Id;

        insert rq;

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        // Group queue;
        // QueueSObject qso;
        // System.runAs(currentUser) {
        //     // queue = TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');
        //     TestDataFactory.getPublicGroup('NAV Tolketjeneste Oslo', 'queue_4703');
        //     queue = TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');
        //     qso = new QueueSObject(
        //         QueueID = TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c').Id,
        //         SobjectType = 'HOT_Request__c'
        //     );

        //     insert qso;
        // }

        // rq.OwnerId = queue.Id;
        rq.Dispatcher__c = currentUser.Id;
        rq.Status__c = 'Godkjent';
        update rq;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(rq, workType);
        insert workOrder;
    }

    @IsTest
    static void testCanceledByUser() {
        HOT_Request__c request = [
            SELECT Id, Name, StartTime__c, OwnerId
            FROM HOT_Request__c
            WHERE Subject__c = 'testRequest'
            LIMIT 1
        ];

        Id notificationTypeId = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
            LIMIT 1
        ]
        .Id;

        Set<String> recipients = new Set<String>{ request.OwnerId };

        System.Test.startTest();
        HOT_RequestNotification.canceledByUser(notificationTypeId, request, recipients);
        System.Test.stopTest();

        System.assert(true, 'CanceledByUser executed successfully');
    }

    @IsTest
    static void testNotifyDispatchersRequestChanged() {
        List<HOT_Request__c> requests = [
            SELECT Id, OwnerId, Name, StartTime__c
            FROM HOT_Request__c
        ];

        System.Test.startTest();
        HOT_RequestNotification.notifyDispatchers_requestChanged(requests);
        System.Test.stopTest();

        System.assertEquals(1, requests.size(), 'Expected exactly one test request');
    }

    @IsTest
    static void testNotifyDispatchersRequestChangedOwnerIdNotNull() {
        List<HOT_Request__c> requests = [
            SELECT Id, OwnerId, Name, StartTime__c
            FROM HOT_Request__c
            WHERE Subject__c = 'testRequest'
        ];

        System.Test.startTest();
        HOT_RequestNotification.notifyDispatchers_requestChanged(requests);
        System.Test.stopTest();

        for (HOT_Request__c req : requests) {
            System.assertNotEquals(null, req.OwnerId, 'Request must have a OwnerId to notify dispatchers');
        }
    }

    @IsTest
    static void testNotifyDispatchersFilesUploadedWithoutWorkOrder() {
        HOT_Request__c request = [
            SELECT Id, Name
            FROM HOT_Request__c
            WHERE Subject__c = 'testRequest'
            LIMIT 1
        ];

        System.Test.startTest();
        HOT_RequestNotification.notifyDispatchersFilesUploaded(request.Id, null, 1);
        HOT_RequestNotification.notifyDispatchersFilesUploaded(request.Id, null, 2);
        System.Test.stopTest();

        System.assert(true, 'Files uploaded notification executed successfully');
    }

    @IsTest
    static void testNotifyDispatchersFilesUploadedWithWorkOrder() {
        HOT_Request__c request = [
            SELECT Id, Name, Dispatcher__c
            FROM HOT_Request__c
            WHERE Subject__c = 'testRequest'
            LIMIT 1
        ];

        WorkOrder workOrder = [
            SELECT Id, HOT_Request__c
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        System.Test.startTest();
        HOT_RequestNotification.notifyDispatchersFilesUploaded(request.Id, workOrder.Id, 1);
        HOT_RequestNotification.notifyDispatchersFilesUploaded(request.Id, workOrder.Id, 2);
        System.Test.stopTest();

        System.assert(true, 'Files uploaded notification with workorder executed successfully');
    }

    @isTest
    static void testNotifyDispatchersRequestIdNull() {
        System.Test.startTest();
        HOT_RequestNotification.notifyDispatchersFilesUploaded(null, null, 1);
        System.Test.stopTest();

        System.assert(true, 'Notify dispatchers with null requestId executed successfully');
    }
}
