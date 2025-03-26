public without sharing class HOT_NotificationCentreController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_Notification__c> getMyNotifications() {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        List<ServiceResource> sr = [
            SELECT Id
            FROM ServiceResource
            WHERE CRM_Domain__c = 'HOT' AND RelatedRecordId = :currentUser.Id
        ];
        Set<Id> serviceResourceIds = new Set<Id>();
        for (ServiceResource resource : sr) {
            serviceResourceIds.add(resource.Id);
        }
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
            WHERE
                (HOT_Account__c = :currentUser.AccountId
                OR HOT_ServiceResource__c IN :serviceResourceIds)
                AND CreatedDate = LAST_N_DAYS:30
        ];
        return notifications;
    }
    @AuraEnabled
    public static void createNotification(List<HOT_Notification__c> notificationsToInsert) {
        if (!notificationsToInsert.isEmpty()) {
            insert notificationsToInsert;
        }
    }
    @AuraEnabled
    public static HOT_Notification__c getNotificationType(String notificationId) {
        HOT_Notification__c notification = [
            SELECT Id, HOT_RelatedObjectType__c, HOT_RelatedObject__c
            FROM HOT_Notification__c
            WHERE Id = :notificationId
        ];
        return notification;
    }
    @AuraEnabled
    public static String getTargetPage(Id workOrderId) {
        String target = '';
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        WorkOrder wo = [
            SELECT
                Id,
                HOT_Request__c,
                HOT_Request__r.IsAccountEqualOrderer__c,
                HOT_Request__r.Orderer__c,
                HOT_Request__r.Account__c
            FROM WorkOrder
            WHERE Id = :workOrderId
        ];
        if (
            wo.HOT_Request__r.IsAccountEqualOrderer__c == true ||
            (wo.HOT_Request__r.IsAccountEqualOrderer__c == false &&
            wo.HOT_Request__r.Account__c == user.AccountId)
        ) {
            target = 'mine-bestillinger';
        } else {
            target = 'mine-bestillinger-andre';
        }
        return target;
    }
}
