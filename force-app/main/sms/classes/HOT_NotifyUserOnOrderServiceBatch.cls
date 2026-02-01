public without sharing class HOT_NotifyUserOnOrderServiceBatch implements Database.Batchable<sObject>, Schedulable {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    public void execute(SchedulableContext sc) {
        HOT_NotifyUserOnOrderServiceBatch instance = new HOT_NotifyUserOnOrderServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        String query = 'SELECT ';
        query += 'Id, Account__c, Account__r.CRM_Person__r.HOT_MobilePhone__c, IsSerieoppdrag__c, SeriesPeriod__c, StartTime__c, EndTime__c, Account__r.CRM_Person__r.HOT_NotificationChannel__c ';
        query += 'FROM HOT_Request__c ';
        query += 'WHERE Status__c = \'Godkjent\' ';
        query += 'AND ((Account__r.CRM_Person__r.HOT_MobilePhone__c != null ';
        query += 'AND Account__r.CRM_Person__r.HOT_NotificationChannel__c = \'SMS\') ';
        query += 'OR Account__r.CRM_Person__r.HOT_NotificationChannel__c = \'Push-varsel i appen\') ';
        query += 'AND Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE ';
        query += 'AND IsNotNotifyAccount__c = FALSE ';
        query += 'AND IsNotifyUserOnOrder__c = TRUE';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {
        List<HOT_Request__c> pushNotifications = new List<HOT_Request__c>();
        List<HOT_Request__c> smsNotifications = new List<HOT_Request__c>();
        List<Id> accountIds = new List<Id>();

        CustomNotificationType notificationTypePush = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        for (HOT_Request__c request : records) {
            if (request.Account__r.CRM_Person__r.HOT_NotificationChannel__c.contains('SMS')) {
                smsNotifications.add(request);
            } else {
                pushNotifications.add(request);
                accountIds.add(request.Account__c);
            }
        }

        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];
        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }

        try {
            if (!smsNotifications.isEmpty()) {
                HOT_ReminderSMSService.notifyUserOnOrderSMS(smsNotifications);
            }

            if (!pushNotifications.isEmpty()) {
                //creating notification object list
                List<WorkOrder> woList = [
                    SELECT Id, HOT_Request__c
                    FROM WorkOrder
                    WHERE HOT_Request__c IN :pushNotifications
                ];
                Map<Id, Id> requestByOrderMap = new Map<Id, Id>();
                for (WorkOrder wo : woList) {
                    requestByOrderMap.put(wo.HOT_Request__c, wo.Id);
                }
                List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
                for (HOT_Request__c request : pushNotifications) {
                    if (userIdByAccountId.get(request.Account__c) != null) {
                        Set<String> recipients = new Set<String>();

                        recipients.add(userIdByAccountId.get(request.Account__c));
                        HOT_UserNotificationService.newRequestNotification(notificationTypePush, request, recipients);
                        request.IsNotifyUserOnOrder__c = false;
                        //creating notification object
                        HOT_Notification__c notification = new HOT_Notification__c();
                        notification.HOT_Account__c = request.Account__c;
                        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                        notification.HOT_Subject__c = 'Andre har lagt inn en bestilling for deg';
                        if (request.IsSerieoppdrag__c) {
                            notification.HOT_NotificationText__c =
                                'Det er bestilt tolk til deg i perioden ' + request.SeriesPeriod__c;
                        } else {
                            notification.HOT_NotificationText__c =
                                'Det er bestilt tolk til deg. Dato: ' +
                                request.StartTime__c?.format('dd.MM.yyyy', 'Europe/Oslo') +
                                ', kl: ' +
                                request.StartTime__c?.format('HH:mm', 'Europe/Oslo') +
                                ' - ' +
                                request.EndTime__c?.format('HH:mm', 'Europe/Oslo') +
                                '.';
                        }
                        notification.HOT_RelatedObject__c = requestByOrderMap.get(request.Id);
                        notification.HOT_RelatedObjectType__c = request.IsSerieoppdrag__c ? 'request' : 'workOrder';

                        notificationList.add(notification);
                    }
                }
                HOT_DatabaseOperations.updateRecords(pushNotifications);
                //inserting notifications
                try {
                    HOT_NotificationCentreController.createNotification(notificationList);
                } catch (Exception e) {
                    handleException(e);
                }
            }
        } catch (Exception e) {
            handleException(e);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = HOT_Utility.getMinutesUntilNextSMSBatch();
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(
                    new HOT_NotifyUserOnOrderServiceBatch(),
                    'HOT_NotifyUserOnOrderServiceBatch',
                    (Integer) minutes,
                    10
                );
            } catch (Exception e) {
                handleException(e);
            }
        }
    }
}
