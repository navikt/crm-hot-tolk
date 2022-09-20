public with sharing class HOT_MessageHandler extends MyTriggers{
    public override void onAfterInsert(){
        List<Id> inThreads= new List<Id>();
        for (Message__c message : (List<Message__c>) records) {
            if(message.CRM_From_Contact__c!=null){
                inThreads.add(message.CRM_Thread__c); 
            }
        }
        if(!inThreads.isEmpty()){
            HOT_MessagesNotification.Notification(inThreads);
        }
    }
}
