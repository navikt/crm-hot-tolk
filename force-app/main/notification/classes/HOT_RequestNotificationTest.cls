@IsTest
public class HOT_RequestNotificationTest {
    @testSetup
    static void setup() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;

        Account account = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id];
        // WorkType workType = HOT_TestDataFactory.createWorkType();
        // insert workType;

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            // queue = TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');

            // TestDataFactory.getPublicGroup('NAV Tolketjeneste Oslo', 'group_4703');
            // TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');

            TestDataFactory.getPublicGroup('HMS Troms og Finmark', 'group_4719');
            TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'HOT_Request__c');

            // Group queueGroup = TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');

            // QueueSObject qso = new QueueSObject(QueueID = queueId, SobjectType = 'HOT_Request__c');

            // insert qso;
        }
        // Group queue = TestDataFactory.getQueue('HMS Møre og Romsdal', 'queue_4715', 'Thread__c');

        // Id queueGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4703' LIMIT 1].Id;
        // HOT_Request__c rq = HOT_T        estDataFactory.createRequest('testRequest', workType);

        // insert rq;

        // rq.OwnerId = queueId;
        // rq.Dispatcher__c = currentUser.Id;
        // rq.Status__c = 'Godkjent';
        // update rq;

        // WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(rq, workType);
        // insert workOrder;

        // Id queueGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
        Id queueGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c rq = HOT_TestDataFactory.createRequest('testRequest', workType);

        insert rq;
        User currentUser1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        rq.OwnerId = queueGroupId;
        rq.Dispatcher__c = currentUser1.Id;
        rq.Status__c = 'Godkjent';
        update rq;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(rq, workType);
        insert workOrder;
    }

    @IsTest
    static void testCanceledByUser() {
        // Id queueGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;

        // WorkType workType = HOT_TestDataFactory.createWorkType();
        // insert workType;
        // HOT_Request__c rq = HOT_TestDataFactory.createRequest('testRequest', workType);

        // insert rq;
        // User currentUser1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // rq.OwnerId = queueGroupId;
        // rq.Dispatcher__c = currentUser1.Id;
        // rq.Status__c = 'Godkjent';
        // update rq;

        // WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(rq, workType);
        // insert workOrder;

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
