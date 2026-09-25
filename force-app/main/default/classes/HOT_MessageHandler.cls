public without sharing class HOT_MessageHandler extends MyTriggers {
    public override void onBeforeInsert() {
        HOT_ThreadReplyPolicy.addErrorsForClosedThreads((List<Message__c>) records);

        validateTjenesteleverandorMessages((List<Message__c>) records);
    }

    private void validateTjenesteleverandorMessages(List<Message__c> messages) {
        for (Message__c message : messages) {
            if (
                message.HOT_User_Role__c != null &&
                message.HOT_User_Role__c.contains('Tjenesteleverandør') &&
                message.CRM_From_User__c != null
            ) {
                message.HOT_IsTjenesteleverandorMessage__c = true;
            }
        }
    }

    public override void onAfterInsert() {
        List<Id> threadIdsToNotifyDispatcherOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyUserOnNewMessage = new List<Id>();
        List<Id> threadIdsToNotifyTjenesteleverandorOnNewMessage = new List<Id>();

        Set<String> allFormidlerThreadType = new Set<String>{
            'HOT_BRUKER-FORMIDLER',
            'HOT_BESTILLER-FORMIDLER',
            'HOT_TOLK-RESSURSKONTOR',
            'HOT_TOLK-FORMIDLER',
            'HOT_TJENESTELEVERANDOR-FORMIDLER'
        };

        Set<String> allTjenesteleverandorThreadTypes = new Set<String>{
            'HOT_TJENESTELEVERANDOR-FORMIDLER',
            'HOT_TJENESTELEVERANDOR-TOLK'
        };

        Set<String> allHotThreadTypes = new Set<String>{
            'HOT_BRUKER-FORMIDLER',
            'HOT_BESTILLER-FORMIDLER',
            'HOT_TOLK-RESSURSKONTOR',
            'HOT_TOLK-FORMIDLER',
            'HOT_TOLK-TOLK',
            'HOT_BRUKER-TOLK',
            'HOT_TJENESTELEVERANDOR-TOLK'
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
            if (allTjenesteleverandorThreadTypes.contains(type)) {
                if (role != null && !role.contains(', Tjenesteleverandør')) {
                    threadIdsToNotifyTjenesteleverandorOnNewMessage.add(message.CRM_Thread__c);
                }
            }
        }

        if (!threadIdsToNotifyDispatcherOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyDispatcher(threadIdsToNotifyDispatcherOnNewMessage);
        }

        if (!threadIdsToNotifyUserOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyUserOnNewMessage(threadIdsToNotifyUserOnNewMessage);
        }
        if (!threadIdsToNotifyTjenesteleverandorOnNewMessage.isEmpty()) {
            HOT_MessagesNotification.NotifyTjenesteleverandorOnNewMessage(
                threadIdsToNotifyTjenesteleverandorOnNewMessage
            );
        }
    }
}
