public without sharing class HOT_InterestedResourceNotification {
    public static void newWantedServiceResource(List<Id> wantedIrIds) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT
                ServiceResource__r.AccountId,
                ServiceResource__r.HOT_MobilePhone__c,
                ServiceResource__r.HOT_NotificationChannel__c,
                ServiceAppointment__r.AppointmentNumber
            FROM HOT_InterestedResource__c
            WHERE Id IN :wantedIrIds
        ];

        if (!interestedResources.isEmpty()) {
            List<Id> accountIds = new List<Id>();

            for (HOT_InterestedResource__c ir : interestedResources) {
                accountIds.add(ir.ServiceResource__r.AccountId);
            }

            List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];

            Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
            for (User user : users) {
                userIdByAccountId.put(user.AccountId, user.Id);
            }
            //creating notification object list
            List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

            for (HOT_InterestedResource__c wantedIr : interestedResources) {
                Set<String> recipients = new Set<String>();
                if (userIdByAccountId.get(wantedIr.ServiceResource__r.AccountId) != null) {
                    recipients.add(userIdByAccountId.get(wantedIr.ServiceResource__r.AccountId));
                }
                if (recipients.size() != 0 && wantedIr.ServiceResource__r.HOT_NotificationChannel__c.contains('Push')) {
                    HOT_UserNotificationService.newWantedSRNotification(
                        getCustomNotificationType('HOT_NotifyUser'),
                        recipients, wantedIr.ServiceAppointment__r.AppointmentNumber
                    );

                    //creating notification object
                    HOT_Notification__c notification = new HOT_Notification__c();
                    notification.HOT_Account__c = wantedIr.ServiceResource__r.AccountId;
                    notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
                    notification.HOT_Subject__c = 'Du er ønsket til et oppdrag. '+wantedIr.ServiceAppointment__r.AppointmentNumber;
                    notification.HOT_NotificationText__c = 'Du kan melde interesse for oppdraget eller avslå.';
                    notification.HOT_RelatedObject__c = wantedIr.Id;
                    notification.HOT_RelatedObjectType__c = 'wanted';

                    notificationList.add(notification);
                } else {
                    Set<Id> wantedIRList = new Set<Id>();
                    wantedIRList.add(wantedIr.Id);
                    HOT_ReminderSMSService.sendSMSOnNewWantedSR(wantedIRList);
                }
            }
            //inserting notifications
            try {
                HOT_NotificationCentreController.createNotification(notificationList);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        }
    }

    public static CustomNotificationType getCustomNotificationType(String devName) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = :devName
        ];
        return notificationType;
    }
}
