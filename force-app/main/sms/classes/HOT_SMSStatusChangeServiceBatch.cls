public without sharing class HOT_SMSStatusChangeServiceBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        String query = 'SELECT ';
        query += 'Id, HOT_Request__r.Orderer__c, HOT_Request__r.Orderer__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c, HOT_Request__r.IsNotNotifyAccount__c, HOT_Interpreters__c, HOT_Request__r.OrdererPhone__c, HOT_Request__r.Type__c, Status, StartDate, EndDate, HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c, AccountId, Account.CRM_Person__c, Account.CRM_Person__r.INT_KrrMobilePhone__c, HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c ';
        query += 'FROM WorkOrder ';
        query += 'WHERE HOT_SendSMSNotificationOnStatusChanged__c = TRUE ';
        query += 'AND (Status = \'Dispatched\' OR Status = \'Cannot Complete\')';
        query += 'AND (HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c = \'SMS\' OR HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c = \'Push-varsel i appen\') ';
        query += 'AND HOT_Request__r.Orderer__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE ';
        query += 'AND HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c = TRUE';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        List<WorkOrder> workorderListPush = new List<WorkOrder>();
        List<WorkOrder> workorderListSMS = new List<WorkOrder>();
        Map<Id, Id> userIdByOrdererAccountId = new Map<Id, Id>();
        Map<Id, String> interpreterNames = HOT_ReminderSMSService.interpreterNamesByWorkOrderIds(records);
        List<Id> accountIds = new List<Id>();

        CustomNotificationType notificationTypePush = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];

        for (WorkOrder wo : records) {
            if (wo.HOT_Request__r.Orderer__r.CRM_Person__r.HOT_NotificationChannel__c.contains('SMS')) {
                workorderListSMS.add(wo);
            } else {
                workorderListPush.add(wo);
                accountIds.add(wo.HOT_Request__r.Orderer__c);
            }
        }

        if (!accountIds.isEmpty()) {
            List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];
            for (User user : users) {
                userIdByOrdererAccountId.put(user.AccountId, user.Id);
            }
        }

        try {
            if (!workorderListSMS.isEmpty()) {
                HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(workorderListSMS);
            }

            if (!workorderListPush.isEmpty()) {
                List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
                for (WorkOrder wo : workorderListPush) {
                    if (userIdByOrdererAccountId.get(wo.HOT_Request__r.Orderer__c) != null) {
                        Set<String> recipients = new Set<String>();
                        recipients.add(userIdByOrdererAccountId.get(wo.HOT_Request__r.Orderer__c));
                        HOT_UserNotificationService.sendNotificationToOrdererOnStatusUpdate(
                            notificationTypePush,
                            wo,
                            interpreterNames.get(wo.Id),
                            recipients
                        );
                        wo.HOT_SendSMSNotificationOnStatusChanged__c = false;
                        //creating notification object
                        HOT_Notification__c notification = new HOT_Notification__c();
                        notification.HOT_Account__c = wo.HOT_Request__r.Orderer__c;
                        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                        notification.HOT_Subject__c = 'Status på din bestilling er endret';
                        if (wo.Status == 'Dispatched') {
                            notification.HOT_NotificationText__c =
                                'Du har fått tolk. Tolk er ' +
                                wo.HOT_Interpreters__c +
                                '\nDato: ' +
                                wo.StartDate?.format('dd.MM.yyyy', 'Europe/Oslo') +
                                ', kl: ' +
                                wo.StartDate?.format('HH:mm', 'Europe/Oslo') +
                                ' - ' +
                                wo.EndDate?.format('HH:mm', 'Europe/Oslo') +
                                '.';
                        }
                        if (wo.Status == 'Cannot Complete') {
                            notification.HOT_NotificationText__c =
                                'Ikke ledig tolk.' +
                                '\nDato: ' +
                                wo.StartDate?.format('dd.MM.yyyy', 'Europe/Oslo') +
                                ', kl: ' +
                                wo.StartDate?.format('HH:mm', 'Europe/Oslo') +
                                ' - ' +
                                wo.EndDate?.format('HH:mm', 'Europe/Oslo') +
                                '.';
                        }
                        notification.HOT_RelatedObject__c = wo.Id;
                        notification.HOT_RelatedObjectType__c = 'workOrder';

                        notificationList.add(notification);
                    }
                }
                HOT_DatabaseOperations.updateRecords(workorderListPush);
                //inserting notifications
                try {
                    HOT_NotificationCentreController.createNotification(notificationList);
                } catch (Exception e) {
                    LoggerUtility logger = new LoggerUtility();
                    logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                    logger.publish();
                }
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
                System.scheduleBatch(
                    new HOT_SMSStatusChangeServiceBatch(),
                    'HOT_SMSStatusChangeServiceBatch',
                    (Integer) minutes,
                    10
                );
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
