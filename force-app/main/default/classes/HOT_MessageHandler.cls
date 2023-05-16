public with sharing class HOT_MessageHandler extends MyTriggers{
    public override void onAfterInsert(){
        List<Id> inThreads= new List<Id>();
        List<Id> notifyUsersThreads= new List<Id>();
        for (Message__c message : (List<Message__c>) records) {
            if(message.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' || message.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER' || message.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' && !(message.HOT_UserRole__c.contains('Formidler'))){
                inThreads.add(message.CRM_Thread__c); 
            }
            if(message.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' || message.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER' || message.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' || message.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK' || message.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' || message.CRM_Thread_Type__c == 'HOT_BRUKER-BESTILLER' || message.CRM_Type__c == 'HOT_TOLK-TOLK'){
                notifyUsersThreads.add(message.CRM_Thread__c); 
            }
        }
        if(!inThreads.isEmpty()){
            HOT_MessagesNotification.Notification(inThreads);
        }
        if(!notifyUsersThreads.isEmpty()){
            HOT_MessagesNotification.NotificationUsers(notifyUsersThreads);
        }
    }
}
