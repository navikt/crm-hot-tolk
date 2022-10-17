public with sharing class HOT_MessageHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<Id> inThreads = new List<Id>();

        CustomNotificationType notificationTypePush = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUserPush'
        ];

        for (Message__c message : (List<Message__c>) records) {
            if (message.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' && message.CRM_From_Contact__c != null) {
                inThreads.add(message.CRM_Thread__c);
            }

            if (message.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' && message.CRM_From_User__c) {
                
            }
        }

        if (!inThreads.isEmpty()) {
            HOT_MessagesNotification.Notification(inThreads);
        }
    }
}
