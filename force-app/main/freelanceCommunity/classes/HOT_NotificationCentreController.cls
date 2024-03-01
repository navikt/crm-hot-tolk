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
            WHERE HOT_Account__c = :currentUser.AccountId AND CreatedDate = LAST_N_DAYS:30
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
    @AuraEnabled
    public static Boolean checkThreadAccess(Id threadId) {
        Boolean hasNotAccess = false;
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<Thread__c> thread = [SELECT Id, CRM_Related_Object__c FROM Thread__c WHERE Id=:threadId];
        Id relatedObjectId = thread[0].CRM_Related_Object__c;
        String objectType = String.valueOf(relatedObjectId.getSObjectType());
        if (objectType == 'WorkOrder') {
            List<ServiceResource> serviceResource = [SELECT Id FROM ServiceResource WHERE AccountId=:user.AccountId AND HOT_IsFreelanceInterpreter__c=TRUE];
            if(serviceResource.size()!=0){
                List<HOT_InterestedResource__c> ir=[SELECT Id, Status__c, ServiceResource__c, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId FROM HOT_InterestedResource__c WHERE ServiceResource__c=:serviceResource[0].Id AND ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId=:thread[0].CRM_Related_Object__c];
                if(ir.size()!=0){
                    if(ir[0].Status__c != 'Assigned'){
                        hasNotAccess = true;
                    }
                }
            }
        }
        return hasNotAccess;
    }
}
