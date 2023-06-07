public with sharing class HOT_MessagesNotification {
    public static void NotifyDispatcher(List<Id> threadIds){
        List<Thread__c> threads=[SELECT Id, Name, OwnerId, HOT_Dispatcher__c, HOT_Subject__c FROM Thread__c WHERE Id IN:threadIds];

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
            notification.setBody(thread.HOT_Subject__c);// send med parameter for denne
            notification.setNotificationTypeId(getCustomNotificationType('HOT_NotifyDispatcher').Id); // send med parameter for denne
            notification.setTargetId(thread.Id);// send med parameter for denne
            HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread);// send med parameter for denne
                
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
