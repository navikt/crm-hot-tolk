public with sharing class HOT_MessagesNotification {
    public HOT_MessagesNotification() {
        
    }
    public static void Notification(List<Id> threadIds){
        List<Thread__c> threads=[SELECT Id, HOT_Dispatcher__c, HOT_Subject__c FROM Thread__c WHERE Id IN:threadIds LIMIT 1];

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        for(Thread__c thread: threads){
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Ny melding');
            notification.setBody(thread.HOT_Subject__c);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(thread.Id);

            Set<String> recipients=new Set<String>();
            recipients.add(thread.HOT_Dispatcher__c);

            if(thread.HOT_Dispatcher__c!=null){

                HOT_NotificationHandler.sendNotification(notification, recipients, thread);
                
            }
            if(thread.HOT_Dispatcher__c==null){
                List<Id>ownerIds=new List<Id>();
                ownerIds.add(thread.OwnerId);
                Map<Id, ID> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(ownerIds);


                Set<String> recipientsqueue=new Set<String>();
                recipientsqueue.add(thread.HOT_Dispatcher__c);
                for(Id owner: groupByQueue.keySet()){
                    recipientsqueue.add(owner);
                    HOT_NotificationHandler.sendNotification(notification, recipientsqueue, thread);
                }
            }
            }
        
    }
}
