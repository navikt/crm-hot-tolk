@IsTest(IsParallel=true)
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

    @IsTest
    private static void newRequestNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        HOT_Request__c request = [
            SELECT Id, StartTime__c, EndTime__c, IsSerieoppdrag__c, SeriesEndDate__c, SeriesStartDate__c
            FROM HOT_Request__c
            LIMIT 1
        ];

        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newRequestNotification(notificationType, request, recipients);
        Test.stopTest();
    }

    @IsTest
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

    @IsTest
    private static void sendNotificationToOrdererOnStatusUpdateTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        WorkOrder workOrder = [
            SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status, HOT_Request__r.Type__c
            FROM WorkOrder
            LIMIT 1
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String interpreters = 'Tolk Vader';

        Test.startTest();
        HOT_UserNotificationService.sendNotificationToOrdererOnStatusUpdate(
            notificationType,
            workOrder,
            interpreters,
            recipients
        );
        Test.stopTest();
    }

    @IsTest
    private static void sendNotificationToOrdererOnStatusUpdateCCTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        WorkOrder workOrder = [
            SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status, HOT_Request__r.Type__c
            FROM WorkOrder
            LIMIT 1
        ];
        workOrder.Status = 'Cannot Complete';
        update workOrder;
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String interpreters = 'Tolk Vader';

        Test.startTest();
        HOT_UserNotificationService.sendNotificationToOrdererOnStatusUpdate(
            notificationType,
            workOrder,
            interpreters,
            recipients
        );
        Test.stopTest();
    }

    @IsTest
    private static void statusChangeNotificationDispatchedTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [
            SELECT HOT_ServiceResource__r.Name, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
        ];
        WorkOrder workOrder = [
            SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.statusChangeNotification(
            notificationType,
            workOrder,
            serviceAppointment,
            recipients
        );
        Test.stopTest();
    }

    @IsTest
    private static void statusChangeNotificationCCTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [
            SELECT HOT_ServiceResource__r.Name, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
        ];
        WorkOrder workOrder = [
            SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Cannot Complete';
        update workOrder;
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.statusChangeNotification(
            notificationType,
            workOrder,
            serviceAppointment,
            recipients
        );
        Test.stopTest();
    }
    @IsTest
    private static void statusChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [
            SELECT HOT_ServiceResource__r.Name, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
        ];
        WorkOrder workOrder = [
            SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.statusChangeNotification(
            notificationType,
            workOrder,
            serviceAppointment,
            recipients
        );
        Test.stopTest();
    }
    @IsTest
    private static void interpreterChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        WorkOrder workOrder = [SELECT Id, StartDate, EndDate, HOT_Interpreters__c, Status FROM WorkOrder LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__r.Name
            FROM ServiceAppointment
            LIMIT 1
        ];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String interpreters = 'Darth Vader';

        Test.startTest();
        HOT_UserNotificationService.interpreterChangeNotification(
            notificationType,
            workOrder,
            interpreters,
            recipients
        );
        Test.stopTest();
    }
    @IsTest
    private static void coInterpreterChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__r.Name, AppointmentNumber, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            LIMIT 1
        ];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String interpreter = 'Darth Vader';
        String target = HOT_ServiceAppointmentNotification.getTargetPageRefInterpreterOnChanged(
            'my',
            serviceAppointment.Id
        );

        Test.startTest();
        HOT_UserNotificationService.coInterpreterChangeNotification(
            notificationType,
            serviceAppointment,
            target,
            interpreter,
            recipients,
            serviceAppointment.AppointmentNumber
        );
        Test.stopTest();
    }
    @IsTest
    private static void coInterpreterRemovedNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__r.Name, AppointmentNumber, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            LIMIT 1
        ];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String target = HOT_ServiceAppointmentNotification.getTargetPageRefInterpreterOnChanged(
            'my',
            serviceAppointment.Id
        );

        Test.startTest();
        HOT_UserNotificationService.coInterpreterRemovedNotification(
            notificationType,
            serviceAppointment,
            target,
            recipients,
            serviceAppointment.AppointmentNumber
        );
        Test.stopTest();
    }
    @IsTest
    private static void newCoInterpreterChangeNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__r.Name, AppointmentNumber, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            LIMIT 1
        ];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        String target = HOT_ServiceAppointmentNotification.getTargetPageRefInterpreterOnChanged(
            'my',
            serviceAppointment.Id
        );
        String interpreter = 'Darth Vader';

        Test.startTest();
        HOT_UserNotificationService.newCoInterpreterChangeNotification(
            notificationType,
            serviceAppointment,
            interpreter,
            target,
            recipients,
            serviceAppointment.AppointmentNumber
        );
        Test.stopTest();
    }

    @IsTest
    private static void newMessageNotificationTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
        thread.CRM_Related_Object__c = request.Id;
        insert thread;
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        Thread__c t = [SELECT Id, CRM_Thread_Type__c, HOT_IsEmployeeThread__c FROM Thread__c LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newMessageNotification(notificationType, t, false, recipients);
        Test.stopTest();
    }

    @IsTest
    private static void newWantedSRNotificationTest() {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_UserNotificationService.newWantedSRNotification(notificationType, recipients, 'SA-00110');
        Test.stopTest();
    }
    @IsTest
    private static void getTargetPageRefThreadTest() {
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.HOT_IsEmployeeThread__c = false;
        thread.CRM_Related_Object_Type__c = 'ServiceAppointment';
        thread.CRM_Related_Object__c = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        insert thread;
        Test.startTest();
        String result = HOT_UserNotificationService.getTargetPageRefThread(thread, true);
        Test.stopTest();
        System.assertEquals(
            '{type: "comm__namedPage",attributes: {pageName: "samtale-frilans"}, state: {recordId: "' +
                thread.Id +
                '", from: "mine-samtaler-frilanstolk"}}',
            result
        );
    }
}
