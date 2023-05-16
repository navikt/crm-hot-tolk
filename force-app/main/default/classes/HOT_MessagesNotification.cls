public with sharing class HOT_MessagesNotification {

     //Dispatcher
    public static void Notification(List<Id> threadIds){
        List<Thread__c> threads=[SELECT Id, Name, OwnerId, HOT_Dispatcher__c, HOT_Subject__c FROM Thread__c WHERE Id IN:threadIds];

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
            notification.setBody(thread.Name);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(thread.Id);
            HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread);
                
        }
    }
    //Users, Interpreters osv
    public static void NotificationUsers(List<Id> notifyUsersThreads){

        List<Thread__c> threads=[SELECT Id, Name, OwnerId, HOT_WorkOrder__r.AccountId, CRM_Related_Object__c, CRM_Thread_Type__c, HOT_Subject__c, HOT_Last_message_from__c FROM Thread__c WHERE Id IN:notifyUsersThreads];

        List<Id> userIds = new List<Id>();
        Map<Id, User> userIdThreadMap = new Map<Id, User>();
        Map<Id, Id> accountIdThreadMap = new Map<Id, Id>();
        List<Id> threadRelatedObjectIds = new List<Id>();

        for (Thread__c thread : threads) {
            threadRelatedObjectIds.add(thread.CRM_Related_Object__c);
            userIds.add(thread.ownerId);
                if(thread.HOT_WorkOrder__r.AccountId!=null){
                    //The user of WO in HOT_BRUKER-TOLK threads
                    accountIdThreadMap.put(thread.HOT_WorkOrder__r.AccountId, thread.Id);
                }
        }
        
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
        ];
        //** 1 - SYSTEM THREADS:
        //HOT_BRUKER-FORMIDLER // owner = bruker
        //HOT_BESTILLER-FORMIDLER // owner = bestiller
        //HOT_TOLK-FORMIDLER // owner = tolk
        //HOT_TOLK-RESSURSKONTOR // owner = tolk
        // + Bruker i tråd HOT_BRUKER-TOLK
        List<Id> accountFromWoIds = new List<Id>();

        List<WorkOrder> workorders=[SELECT Id, Account.Id FROM WorkOrder WHERE Id IN :threadRelatedObjectIds];
        for (WorkOrder wo : workorders) {
            accountFromWoIds.add(wo.Account.Id);
        }
        List<User> users = [SELECT Id, AccountId,Account.CRM_Person__r.HOT_NotificationChannel__c, Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c, ContactId FROM User WHERE Id IN :userIds OR AccountId IN :accountFromWoIds];
    
        for (Thread__c thread : threads) {
            if(CRM_Thread_Type__c=='HOT_BRUKER-FORMIDLER' || CRM_Thread_Type__c=='HOT_BESTILLER-FORMIDLER' || CRM_Thread_Type__c=='HOT_TOLK-FORMIDLER' || CRM_Thread_Type__c=='HOT_TOLK-RESSURSKONTOR')
                for (User user : users) {
                    if (thread.OwnerId == user.Id && thread.HOT_Last_message_from__c != user.ContactId ) {
                        userIdThreadMap.put(thread.Id, user);
                    }
            }
            else if(CRM_Thread_Type__c=='HOT_BRUKER-TOLK'){
                for (User user : users) {
                    if (accountIdThreadMap.containsKey(user.AccountId)) {
                        if(thread.HOT_Last_message_from__c != user.ContactId){
                            userIdThreadMap.put(thread.Id, user);
                        }
                    }
                }
            }
        }
        Set<String> recipients = new Set<String>();
        for (Id threadId : userIdThreadMap.keySet()) {
            User user = userIdThreadMap.get(threadId);
            if(user.Account.CRM_Person__r.HOT_NotificationChannel__c=='Push-varsel i appen' && user.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c==false){
                recipients.add(user.Id);
                HOT_UserNotificationService.newMessageNotification(notificationType, threadId, recipients);
            }
            else if(user.Account.CRM_Person__r.HOT_NotificationChannel__c='SMS' && user.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c==false){
                //SMS SENDING
            }
        }

        // **FLERE PERSONER PÅ SAMTALER:
        // **HOT_BRUKER-BESTILLER // ingen egentlige eiere 
        // **Venter med denne for den var kanskje ikke ønsket allikevel
    
        //**FLERE PERSONER PÅ SAMTALER:

        //HOT_BRUKER-TOLK // ingen egentlige eiere 
        //HOT_TOLK-TOLK // ingen egentlige eiere 

        List<Id> userInterpreterThreadsId = new List<Id>();
        List<Id> interpreterInterpreterThreadsId = new List<Id>();

        for (Thread__c thread : threads) {
            if(thread.CRM_Thread_Type__c=='HOT_BRUKER-TOLK' ){
                userInterpreterThreadsId.add(thread.Id);
            }
            else if(thread.CRM_Thread_Type__c=='HOT_TOLK-TOLK'){
                    interpreterInterpreterThreadsId.add(thread.Id);
            }
        }
        //HOT_BRUKER-TOLK
        if (!userInterpreterThreadsId.isEmpty()) {
            Map<Id, HOT_InterestedResource__c> userInterpreterThreadMap = new Map<Id, HOT_InterestedResource__c>();
            List<HOT_InterestedResource__c> interestedResource = [SELECT Id, Status__c, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id, ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c, ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c, ServiceResource__r.RelatedRecordId, ServiceResource__r.Account.PersonContactId FROM HOT_InterestedResource__c WHERE ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id IN:interpreterInterpreterThreadsId AND Status__c='Assigned'];
            
            for(HOT_InterestedResource__c ir: interestedResource){
                if(ir.ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c=='Push-varsel i appen' && ir.ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c==false){
                    //push map
                    for (Thread__c thread : threads) {
                        if(thread.CRM_Thread_Type__c=='HOT_BRUKER-TOLK' && ir.ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id==thread.CRM_Related_Object__c && thread.HOT_Last_message_from__c!=ir.ServiceResource__r.Account.PersonContactId){
                            userInterpreterThreadMap.put(thread.Id, ir);
                        }
                    }
                }
                else if(ir.ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c=='SMS' && ir.ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c==false){
                    //send SMS
                }
            }
            //Send push her
            Set<String> userInterpretersRecipients = new Set<String>();
                for (Id threadId : userInterpreterThreadMap.keySet()) {
                    HOT_InterestedResource__c irs = userInterpreterThreadMap.get(threadId);
                    userInterpretersRecipients.add(irs.ServiceResource__r.RelatedRecordId);
                    HOT_UserNotificationService.newMessageNotification(notificationType, threadId, userInterpretersRecipients); 
                }

        }
        //HOT_TOLK-TOLK
        if (!interpreterInterpreterThreadsId.isEmpty()) {
            Map<Id, HOT_InterestedResource__c> interpreterInterpreterThreadMap = new Map<Id, HOT_InterestedResource__c>();

            List<HOT_InterestedResource__c> interestedResource = [SELECT Id, Status__c, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id, ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c, ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c, ServiceResource__r.RelatedRecordId, ServiceResource__r.Account.PersonContactId FROM HOT_InterestedResource__c WHERE ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id IN:interpreterInterpreterThreadsId AND Status__c='Assigned'];
            for(HOT_InterestedResource__c ir: interestedResource){
                if(ir.ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c=='Push-varsel i appen' && ir.ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c==false){
                    //push map
                    for (Thread__c thread : threads) {
                        if(thread.CRM_Thread_Type__c=='HOT_TOLK-TOLK' && ir.ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id==thread.CRM_Related_Object__c && thread.HOT_Last_message_from__c!=ir.ServiceResource__r.Account.PersonContactId){
                            interpreterInterpreterThreadMap.put(thread.Id, ir);
                        }
                    }
                }
                else if(ir.ServiceResource__r.Account.CRM_Person__r.HOT_NotificationChannel__c=='SMS' && ir.ServiceResource__r.Account.CRM_Person__r.HOT_IsReservationAgainstNotifications__c==false){
                    //send SMS
                }
            }
            //Send push her
            Set<String> InterpretersRecipients = new Set<String>();
                for (Id threadId : interpreterInterpreterThreadMap.keySet()) {
                    HOT_InterestedResource__c interestedresource = interpreterInterpreterThreadMap.get(threadId);
                    InterpretersRecipients.add(interestedresource.ServiceResource__r.RelatedRecordId);
                    HOT_UserNotificationService.newMessageNotification(notificationType, threadId, InterpretersRecipients); 
                }
            }
    }
}
