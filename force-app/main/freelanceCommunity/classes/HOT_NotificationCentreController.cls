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
                HOT_RelatedObject__c,
                HOT_RelatedObjectType__c,
                CreatedDate
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
    }
}
