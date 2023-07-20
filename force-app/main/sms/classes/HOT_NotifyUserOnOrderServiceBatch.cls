public without sharing class HOT_NotifyUserOnOrderServiceBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_NotifyUserOnOrderServiceBatch instance = new HOT_NotifyUserOnOrderServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        Date horizonDate = Date.today().addDays(2);
        if (now.format('EEEE') == 'Friday') {
            horizonDate = Date.today().addDays(4);
        }
        String query = 'SELECT ';
        query += 'Id, Account__c, Account__r.CRM_Person__r.INT_KrrMobilePhone__c, IsSerieoppdrag__c, SeriesStartDate__c, SeriesEndDate__c, StartTime__c, EndTime__c, Account__r.CRM_Person__r.HOT_NotificationChannel__c ';
        query += 'FROM HOT_Request__c ';
        query += 'WHERE Status__c = \'Godkjent\' ';
        query += 'AND ((Account__r.CRM_Person__r.INT_KrrMobilePhone__c != null ';
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
                for (HOT_Request__c request : pushNotifications) {
                    if (userIdByAccountId.get(request.Account__c) != null) {
                        Set<String> recipients = new Set<String>();
                        recipients.add(userIdByAccountId.get(request.Account__c));
                        HOT_UserNotificationService.newRequestNotification(notificationTypePush, request, recipients);
                        request.IsNotifyUserOnOrder__c = false;
                    }
                }
                HOT_DatabaseOperations.updateRecords(pushNotifications);
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = HOT_Utility.getMinutesUntilNextSMSBatch();
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(new HOT_NotifyUserOnOrderServiceBatch(), 'HOT_NotifyUserOnOrderServiceBatch', (Integer) minutes, 10);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
