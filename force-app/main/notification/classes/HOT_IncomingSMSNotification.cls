public with sharing class HOT_IncomingSMSNotification {
    private static final Integer MAX_NOTIFICATION_BODY_CHARACTERS = 320;
    public static final String DISPATCH_INCOMING_NUMBER = '41716090';

    @TestVisible
    private class NotificationContext {
        public SMS__c sms;
        public Set<String> recipients;
        public Messaging.CustomNotification notification;
    }

    public static Integer notifyDispatchersOnIncomingSMS(List<SMS__c> messages) {
        List<NotificationContext> contexts = prepareContextsForValidSMS(messages);

        for (NotificationContext context : contexts) {
            HOT_NotificationHandler.sendNotification(context.notification, context.recipients, (SObject) context.sms);
        }
        return contexts.size();
    }

    @TestVisible
    private static List<NotificationContext> prepareContextsForValidSMS(List<SMS__c> messages) {
        List<NotificationContext> contextList = new List<NotificationContext>();

        Map<Id, List<NotificationContext>> accountIdToContexts = new Map<Id, List<NotificationContext>>();
        Set<Id> smsIds = new Set<Id>();
        for (SMS__c sms : messages) {
            smsIds.add(sms.Id);
        }

        Map<Id, SMS__c> smsRecords = new Map<Id, SMS__c>(
            [SELECT Account__c, Domain__c, Type__c, Recipient__c, Message__c FROM SMS__c WHERE Id IN :smsIds]
        );

        for (SMS__c sms : messages) {
            if (shouldNotifyDispatchersAboutSMS(smsRecords.get(sms.Id))) {
                NotificationContext context = new NotificationContext();
                context.sms = smsRecords.get(sms.Id);
                List<NotificationContext> contexts = accountIdToContexts.get(smsRecords.get(sms.Id).Account__c);
                if (contexts == null) {
                    contexts = new List<NotificationContext>();
                }
                contexts.add(context);
                accountIdToContexts.put(smsRecords.get(sms.Id).Account__c, contexts);
            }
        }

        if (accountIdToContexts.isEmpty()) {
            return contextList;
        }

        List<Person__c> senders = [
            SELECT Id, CRM_Account__c, INT_RegionNumber__c, INT_MunicipalityNumber__c, CRM_FullName__c
            FROM Person__c
            WHERE CRM_Account__c IN :accountIdToContexts.keySet()
        ];
        List<Id> queueIds = getQueueIdsFromSenders(senders);
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        Integer index = 0;
        for (Person__c sender : senders) {
            List<NotificationContext> contexts = accountIdToContexts.get(sender.CRM_Account__c);
            for (NotificationContext context : contexts) {
                context.recipients = new Set<String>{ (String) groupByQueue.get(queueIds[index]) };

                String title = 'Melding fra ' + sender.CRM_FullName__c;
                String body = context.sms.Message__c.length() > MAX_NOTIFICATION_BODY_CHARACTERS
                    ? context.sms.Message__c.substring(0, MAX_NOTIFICATION_BODY_CHARACTERS - 3) + '...'
                    : context.sms.Message__c;

                context.notification = HOT_NotificationHandler.prepareNotification(
                    title,
                    body,
                    notificationType.Id,
                    context.sms.Id
                );
                contextList.add(context);
            }
            index++;
        }

        return contextList;
    }

    @TestVisible
    private static List<Id> getQueueIdsFromSenders(List<Person__c> senders) {
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer senderIndex = 0;

        for (Person__c sender : senders) {
            SobjectWrapper wrapper = new SobjectWrapper(
                senderIndex,
                sender.INT_MunicipalityNumber__c,
                sender.INT_RegionNumber__c
            );
            wrapper.confidential = 'Ugradert';
            wrappers.add(wrapper);
            senderIndex++;
        }

        Map<Integer, ApexSharingRuleWrapper> indexToSharingRule = RecordOwnerService.getQueuesAndNavUnits(
            wrappers,
            'Person__c'
        );

        senderIndex = 0;
        List<Id> queueIds = new List<Id>();

        Group adminGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HOT_Tolk_Admin' LIMIT 1];
        for (Person__c sender : senders) {
            ApexSharingRuleWrapper rule = indexToSharingRule.get(senderIndex);
            if (rule != null) {
                queueIds.add(rule.queueId);
            } else {
                queueIds.add(adminGroup.Id);
            }
            senderIndex++;
        }

        return queueIds;
    }

    @TestVisible
    private static Boolean shouldNotifyDispatchersAboutSMS(SMS__c sms) {
        return sms.Account__c != null &&
            sms.Domain__c == 'HOT' &&
            sms.Type__c == 'Incoming SMS' &&
            sms.Recipient__c == DISPATCH_INCOMING_NUMBER;
    }
}
