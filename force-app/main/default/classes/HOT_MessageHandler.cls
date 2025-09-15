public without sharing class HOT_MessageHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<Id> threadIdsToNotifyDispatcherOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyUserOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyInterpretersOnNewMessage = new List<Id>();

        Set<String> threadType = new Set<String>{
            'HOT_BRUKER-FORMIDLER',
            'HOT_BESTILLER-FORMIDLER',
            'HOT_TOLK-RESSURSKONTOR',
            'HOT_TOLK-FORMIDLER'
        };

        for (Message__c message : (List<Message__c>) records) {
            String type = message.CRM_Thread_Type__c;
            String role = message.HOT_User_Role__c;

            if (threadType.contains(type)) {
                if (role != null && !role.contains(', Formidler')) {
                    threadIdsToNotifyDispatcherOnNewMessage.add(message.CRM_Thread__c);
                } else {
                    if (type == 'HOT_TOLK-FORMIDLER') {
                        threadIdsToNotifyInterpretersOnNewMessage.add(message.CRM_Thread__c);
                    } else {
                        threadIdsToNotifyUserOnNewMessage.add(message.CRM_Thread__c);
                    }
                }
            } else {
                switch on type {
                    when 'HOT_TOLK-TOLK' {
                        threadIdsToNotifyInterpretersOnNewMessage.add(message.CRM_Thread__c);
                    }
                    when 'HOT_BRUKER-TOLK' {
                        if (role != null && role.contains(', Tolkebruker')) {
                            threadIdsToNotifyInterpretersOnNewMessage.add(message.CRM_Thread__c);
                        } else {
                            threadIdsToNotifyUserOnNewMessage.add(message.CRM_Thread__c);
                        }
                    }
                }
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
