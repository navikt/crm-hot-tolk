@isTest
public class HOT_UserNotificationServiceTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        Thread__c thread = HOT_TestDataFactory.createThread();
        insert thread;
    }

    @isTest
    private static void newWorkOrderNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Push-test', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert wo;

        wo.Subject = 'Push-test 2';
        wo.Account.CRM_Person__r.HOT_NotificationChannel__c = 'Push-varsel i appen';
        update wo;

        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status  FROM WorkOrder WHERE Subject = 'Push-test 2' LIMIT 1];
        
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newWorkOrderNotification(notificationType, workOrder, recipients);
        Test.stopTest();
    }

    @isTest
    private static void statusChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status FROM WorkOrder LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.statusChangeNotification(notificationType, workOrder, recipients);
        Test.stopTest();
    }
    @isTest
    private static void interpreterChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status FROM WorkOrder LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.interpreterChangeNotification(notificationType, workOrder, recipients);
        Test.stopTest();
    }
    @isTest
    private static void newMessageNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Thread__c thread = [SELECT Id FROM Thread__c LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newMessageNotification(notificationType, thread, recipients);
        Test.stopTest();
    }
}
