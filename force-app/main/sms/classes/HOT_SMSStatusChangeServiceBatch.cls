public without sharing class HOT_SMSStatusChangeServiceBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        String query = 'SELECT ';
        query += 'Id, HOT_Request__r.Orderer__c, HOT_Request__r.OrdererPhone__c, HOT_Request__r.Type__c, Status, StartDate, EndDate, HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c, AccountId, Account.CRM_Person__c, Account.CRM_Person__r.INT_KrrMobilePhone__c, Account.CRM_Person__r.HOT_Notificationchannel__c, Account.OwnerId ';
        query += 'FROM WorkOrder ';
        query += 'WHERE HOT_SendSMSNotificationOnStatusChanged__c = TRUE ';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        List<WorkOrder> smsNotificationList= new List<WorkOrder>();
        List<WorkOrder> pushNotificationList= new List<WorkOrder>();
        List<Id> accountIds = new List<Id>();
         CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        try {
            for(WorkOrder wo: records){
                if(wo.Account.CRM_Person__r.HOT_Notificationchannel__c=='SMS'){
                    smsNotificationList.add(wo);
                    
                   }
                   else{
                    pushNotificationList.add(wo);
                    accountIds.add(wo.AccountId);
                }
            }
            List<User> users=[SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];
            Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
            for (User user : users) {
                userIdByAccountId.put(user.AccountId, user.Id);
            }
            if (!pushNotificationList.isEmpty()) {
            for (WorkOrder wo : pushNotificationList) {
                Set<String> recipients = new Set<String>();
                recipients.add(userIdByAccountId.get(wo.AccountId));
                if (recipients.size() != 0) {
                    HOT_UserNotificationService.statusChangeNotification(notificationType, wo, recipients);
                }
            }
        }
        HOT_ReminderSMSService.sendSMSToOrdererOnStatusUpdate(records);
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
