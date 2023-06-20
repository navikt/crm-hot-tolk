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
        query += 'Id, Account__r.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate, Account__r.CRM_Person__r.HOT_NotificationChannel__c ';
        query += 'FROM HOT_Request__c ';
        query += 'WHERE Status = \'Godkjent\' ';
        query += 'AND Account__r.CRM_Person__r.INT_KrrMobilePhone__c != null ';
        query += 'AND Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE ';
        query += 'AND (Account__r.CRM_Person__r.HOT_NotificationChannel__c = \'SMS\' ';
        query += 'OR Account__r.CRM_Person__r.HOT_NotificationChannel__c = \'Push-varsel i appen\') ';
        query += 'AND HOT_Request__r.IsNotNotifyAccount__c = FALSE ';  
        query += 'AND IsNotifyUserOnOrder__c = TRUE'; 

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<HOT_Request__c> records) {
        List<WorkOrder> workorderListPush = new List<WorkOrder>();
        List<WorkOrder> workorderListSMS = new List<WorkOrder>();
        List<Id> accountIds = new List<Id>();

        CustomNotificationType notificationTypePush = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        for (WorkOrder wo : records) {
            if (wo.Account.CRM_Person__r.HOT_NotificationChannel__c.contains('SMS')) {
                workorderListSMS.add(wo);
            } else {
                workorderListPush.add(wo);
                accountIds.add(wo.AccountId);
            }
        }

        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];
        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }

        try {
            if (!workorderListSMS.isEmpty()) {
                HOT_ReminderSMSService.reminderSMS(records);
            }

            if (!workorderListPush.isEmpty()) {
                for (WorkOrder wo : workorderListPush) {
                    if (userIdByAccountId.get(wo.AccountId) != null) {
                        Set<String> recipients = new Set<String>();
                        recipients.add(userIdByAccountId.get(wo.AccountId));
                        HOT_UserNotificationService.reminderNotification(notificationTypePush, wo, recipients);
                        wo.HOT_IsReminderSMSSendt__c = true;
                    }
                }
                HOT_DatabaseOperations.updateRecords(workorderListPush);
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = HOT_Utility.getMinutesUntilNextReminderSMSBatch();
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(new HOT_ReminderSMSBatch(), 'HOT_ReminderSMSBatch', (Integer) minutes, 10);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
