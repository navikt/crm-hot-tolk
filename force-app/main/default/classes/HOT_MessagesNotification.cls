public with sharing class HOT_MessagesNotification {
    public static void Notification(List<Id> threadIds){
        List<Thread__c> threads=[SELECT Id, OwnerId, HOT_Dispatcher__c, HOT_Subject__c FROM Thread__c WHERE Id IN:threadIds];

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        List<Id> ownerIds=new List<Id>();
        for(Thread__c thread : threads){
                ownerIds.add(thread.OwnerId);
        }
        Map<Id, ID> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(ownerIds);

        for(Thread__c thread : threads){
            Set<String> recipients = new Set<String>();
            if(thread.HOT_Dispatcher__c!=null){
                recipients.add(thread.HOT_Dispatcher__c);
            }
            else {
                recipients.add(groupByQueue.get(thread.OwnerId));
            }
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Ny melding');
            notification.setBody(thread.HOT_Subject__c);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(thread.Id);
            HOT_NotificationHandler.sendNotification(notification, recipients, thread);
                
        }
    }
}
