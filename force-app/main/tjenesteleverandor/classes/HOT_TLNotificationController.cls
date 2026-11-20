public without sharing class HOT_TLNotificationController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_Notification__c> getMyNotifications() {
        return [
            SELECT
                Id,
                HOT_Subject__c,
                HOT_NotificationText__c,
                HOT_RelatedObject__c,
                HOT_RelatedObjectType__c,
                HOT_IsRead__c,
                CreatedDate
            FROM HOT_Notification__c
            WHERE Tjenesteleverandor__c = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void markAllNotificationsAsRead() {
        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_IsRead__c
            FROM HOT_Notification__c
            WHERE Tjenesteleverandor__c = :UserInfo.getUserId() AND HOT_IsRead__c = FALSE
        ];

        for (HOT_Notification__c notification : notifications) {
            notification.HOT_IsRead__c = true;
        }

        if (!notifications.isEmpty()) {
            try {
                update notifications;
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        }
    }
}
