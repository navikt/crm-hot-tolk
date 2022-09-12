public with sharing class HOT_MessageHandler {
    public void onAfterInsert(){

        for (Message__c message : (List<Message__c>) Message__c) {
            if(message.CRM_From_Contact__c!=null){
                 HOT_MessagesNotification.Notification(message.CRM_Thread__c);
            }
        }
    }
}
