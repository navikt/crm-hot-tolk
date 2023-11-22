public without sharing class HOT_MessageHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<Id> threadIdsToNotifyDispatcherOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyUserOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyInterpretersOnNewMessage = new List<Id>();

        for (Message__c message : (List<Message__c>) records) {
            if (
                message.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' ||
                message.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER' ||
                message.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                message.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER'
            ) {
                if (!message.HOT_UserRole__c.contains(', Formidler')) {
                    threadIdsToNotifyDispatcherOnNewMessage.add(message.CRM_Thread__c);
                } else {
                    if (
                        message.CRM_Thread_Type__c != 'HOT_TOLK-FORMIDLER' ||
                        message.CRM_Thread_Type__c != 'HOT_TOLK-RESSURSKONTOR'
                    ) {
                        threadIdsToNotifyUserOnNewMessage.add(message.CRM_Thread__c);
                    }
                    if (
                        message.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
                        message.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR'
                    ) {
                        threadIdsToNotifyInterpretersOnNewMessage.add(message.CRM_Thread__c);
                    }
                }
            }
            if (message.CRM_Thread_Type__c == 'HOT_TOLK-TOLK') {
                threadIdsToNotifyInterpretersOnNewMessage.add(message.CRM_Thread__c);
            }
            if (message.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK') {
                threadIdsToNotifyUserOnNewMessage.add(message.CRM_Thread__c);
                threadIdsToNotifyInterpretersOnNewMessage.add(message.CRM_Thread__c);
            }
        }

        if (!threadIdsToNotifyDispatcherOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyDispatcher(threadIdsToNotifyDispatcherOnNewMessage);
        }

        if (!threadIdsToNotifyUserOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyUser(threadIdsToNotifyUserOnNewMessage);
        }
        if (!threadIdsToNotifyInterpretersOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyInterpreter(threadIdsToNotifyInterpretersOnNewMessage);
        }
    }
}
