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
    }

    @isTest
    private static void newWorkOrderNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status  FROM WorkOrder LIMIT 1];
        
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newWorkOrderNotification(notificationType, workOrder, recipients);
        Test.stopTest();
    }

    @isTest
    private static void newRequestNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        
        HOT_Request__c request = [SELECT Id, StartTime__c, EndTime__c, IsSerieoppdrag__c, SeriesEndDate__c, SeriesStartDate__c  FROM HOT_Request__c LIMIT 1];
        
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newRequestNotification(notificationType, request, recipients);
        Test.stopTest();
    }

    @isTest
    private static void reminderNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
  
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status FROM WorkOrder LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.reminderNotification(notificationType, workOrder, recipients);
        Test.stopTest();
    }

    @isTest
    private static void sendNotificationToOrdererOnStatusUpdateTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
  
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status, HOT_Request__r.Type__c FROM WorkOrder LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String interpreters = 'Tolk Vader';

        Test.startTest();
        HOT_UserNotificationService.sendNotificationToOrdererOnStatusUpdate(notificationType, workOrder,interpreters, recipients);
        Test.stopTest();
    }

    @isTest
    private static void statusChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [SELECT HOT_ServiceResource__r.Name, Status, HOT_WorkOrderLineItem__r.WorkOrderId
        FROM ServiceAppointment];
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status FROM WorkOrder WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.statusChangeNotification(notificationType, workOrder, serviceAppointment, recipients);
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
        ServiceAppointment serviceAppointment = [SELECT Id, HOT_ServiceResource__r.Name FROM ServiceAppointment LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String interpreters = 'Darth Vader';

        Test.startTest();
        HOT_UserNotificationService.interpreterChangeNotification(notificationType, workOrder, interpreters, recipients);
        Test.stopTest();
    }
    @isTest
    private static void newMessageNotificationTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c='HOT_BRUKER-FORMIDLER';
        thread.CRM_Related_Object__c=request.Id;
        insert thread;
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Thread__c t = [SELECT Id, CRM_Thread_Type__c, HOT_IsEmployeeThread__c FROM Thread__c LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newMessageNotification(notificationType, t, recipients);
        Test.stopTest();
    }
}
