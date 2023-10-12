public without sharing class HOT_NotificationCentreController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_Notification__c> getMyNotifications() {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        List<HOT_Notification__c> notifications = [
            SELECT
                Id,
                HOT_Account__c,
                HOT_IsRead__c,
                HOT_NotificationChannel__c,
                HOT_Subject__c,
                HOT_NotificationText__c,
                HOT_RelatedObject__c
            FROM HOT_Notification__c
            WHERE HOT_Account__c = :currentUser.AccountId
        ];
        return notifications;
    }
    @AuraEnabled
    public static void createNotification(List<HOT_Notification__c> notificationsToInsert) {
        if (!notificationsToInsert.isEmpty()) {
            insert notificationsToInsert;
        }
        // List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        // HOT_Notification__c notification= new HOT_Notification__c();
        // notification.HOT_Account__c
        // notification.HOT_NotificationChannel__c
        // notification.HOT_Subject__c
        // notification.HOT_NotificationText__c
        // notification.HOT_RelatedObject__c

        // notificationList.add(notification);

        // HOT_NotificationCentreController.createNotification(notificationList);
    }
}
