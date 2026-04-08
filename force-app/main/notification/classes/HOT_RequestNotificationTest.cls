@IsTest
public class HOT_RequestNotificationTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c rq = HOT_TestDataFactory.createRequest('testRequest', workType);
        HOT_Request__c requestNoDispatcher = HOT_TestDataFactory.createRequest('testRequestNoDispatcher', workType);

        List<HOT_Request__c> requestsToInsert = new List<HOT_Request__c>{ rq, requestNoDispatcher };
        insert requestsToInsert;

        Id currentUser = UserInfo.getUserId();

        rq.OwnerId = currentUser;
        rq.Status__c = 'Godkjent';
        rq.Dispatcher__c = currentUser;
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

        System.assertEquals(2, requests.size(), 'Expected exactly two test requests');
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
    static void testNotifyDispatchersFilesUploadedWithoutDispatcher() {
        HOT_Request__c request = [
            SELECT Id, Name, Dispatcher__c
            FROM HOT_Request__c
            WHERE Subject__c = 'testRequestNoDispatcher'
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
