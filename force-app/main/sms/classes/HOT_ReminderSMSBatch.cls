public without sharing class HOT_ReminderSMSBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_ReminderSMSBatch instance = new HOT_ReminderSMSBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        Date horizonDate = Date.today().addDays(2);
        if (now.format('EEEE') == 'Friday') {
            horizonDate = Date.today().addDays(4);
        }
        String query = 'SELECT ';
        query += 'Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate, Account.CRM_Person__r.HOT_NotificationChannel__c ';
        query += 'FROM WorkOrder ';
        query += 'WHERE StartDate < :horizonDate ';
        query += 'AND StartDate > :now ';
        query += 'AND Status = \'Dispatched\' ';
        query += 'AND Account.CRM_Person__r.INT_KrrMobilePhone__c != null ';
        query += 'AND Account.CRM_Person__r.HOT_IsReservationAgainstReminderSMS__c = FALSE ';
        query += 'AND (Account.CRM_Person__r.HOT_NotificationChannel__c = \'SMS\' ';
        query += 'OR Account.CRM_Person__r.HOT_NotificationChannel__c = \'Push-varsel i appen\') ';
        query += 'AND HOT_Request__r.IsReminderSMS__c = TRUE '; //Should consider renaming field to IsReminderNotification__c
        query += 'AND HOT_Request__r.IsNotNotifyAccount__c = FALSE '; //In some cases (See TOLK-2234) we absolutely do not want to send notification to whomever the order concerns
        query += 'AND HOT_IsReminderSMSSendt__c = FALSE'; //Should consider renaming HOT_IsReminderNotificiationSent__c

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
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
        //creating notification object list
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
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
                        //creating notification object
                        HOT_Notification__c notification = new HOT_Notification__c();
                        notification.HOT_Account__c = wo.AccountId;
                        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                        notification.HOT_Subject__c = 'Påminnelse om tolkebestilling';
                        notification.HOT_NotificationText__c =
                            'Dato: ' +
                            wo.StartDate?.format('dd.MM.yyyy HH:mm', 'Europe/Oslo') +
                            ' - ' +
                            wo.EndDate?.format('HH:mm', 'Europe/Oslo') +
                            '.';
                        notification.HOT_RelatedObject__c = wo.Id;
                        notification.HOT_RelatedObjectType__c = 'workOrder';

                        notificationList.add(notification);
                    }
                }
                HOT_DatabaseOperations.updateRecords(workorderListPush);
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
        //inserting notifications
        HOT_NotificationCentreController.createNotification(notificationList);
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
