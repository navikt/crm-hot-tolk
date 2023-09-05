public without sharing class HOT_InterestedResourceNotification {
    public static void newWantedServiceResource(List<Id> wantedIrIds) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT ServiceResource__r.AccountId, ServiceResource__r.Account.INT_KrrMobilePhone__c, ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c, ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c
            FROM HOT_InterestedResource__c
            WHERE
                Id IN :wantedIrIds AND ServiceAppointment__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c = FALSE];

        List<Id> accountIds = new List<Id>();

         for (HOT_InterestedResource__c ir : interestedResources) {
             accountIds.add(ir.ServiceResource__r.AccountId);
         }

        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds];

        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }
        if (!interestedResources.isEmpty()) {
            for (HOT_InterestedResource__c wantedIr : interestedResources) {
                Set<String> recipients = new Set<String>();
                recipients.add(userIdByAccountId.get(wantedIr.ServiceResource__r.AccountId));
                if(wantedIr.ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c.contains('Push')){
                    //PUSH
                      HOT_UserNotificationService.newWanterSRNotification(getCustomNotificationType('HOT_Wanted_ServiceResource'),wantedIr,recipients);
                }
                else{
                    //SMS
                    Set<Id> wantedIRList = new Set<Id>();
                    wantedIRList.add(wantedIr.Id);
                    HOT_ReminderSMSService.sendSMSOnNewWantedSR(wantedIRList);

                }

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