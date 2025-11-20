public without sharing class HOT_MessageHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<Id> threadIdsToNotifyDispatcherOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyUserOnNewMessage = new List<Id>();

        Set<String> allFormidlerThreadType = new Set<String>{
            'HOT_BRUKER-FORMIDLER',
            'HOT_BESTILLER-FORMIDLER',
            'HOT_TOLK-RESSURSKONTOR',
            'HOT_TOLK-FORMIDLER'
        };

        Set<String> allHotThreadTypes = new Set<String>{
            'HOT_BRUKER-FORMIDLER',
            'HOT_BESTILLER-FORMIDLER',
            'HOT_TOLK-RESSURSKONTOR',
            'HOT_TOLK-FORMIDLER',
            'HOT_TOLK-TOLK',
            'HOT_BRUKER-TOLK'
        };

        for (Message__c message : (List<Message__c>) records) {
            String type = message.CRM_Thread_Type__c;
            String role = message.HOT_User_Role__c;

            if (allFormidlerThreadType.contains(type)) {
                if (role != null && !role.contains(', Formidler')) {
                    threadIdsToNotifyDispatcherOnNewMessage.add(message.CRM_Thread__c);
                }
            }
            if (allHotThreadTypes.contains(type)) {
                threadIdsToNotifyUserOnNewMessage.add(message.CRM_Thread__c);
            }
        }

        if (!threadIdsToNotifyDispatcherOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyDispatcher(threadIdsToNotifyDispatcherOnNewMessage);
        }

        if (!threadIdsToNotifyUserOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyUserOnNewMessage(threadIdsToNotifyUserOnNewMessage);
        }
    }
}
