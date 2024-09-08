public with sharing class HOT_IncomingSMSNotification {
    public static String DISPATCH_INCOMING_NUMBER = '41716090';

    public static void notifyDispatchersOnIncomingSMS(List<SMS__c> messages) {

        Map<Id, SMS__c> senderAccountIdToSms = new Map<Id, SMS__c>();

        for(SMS__c sms : messages) {
            if(shouldNotifyDispatchersAboutSMS(sms)) {
                senderAccountIdToSms.put(sms.Account__c, sms);
            }
        }

        List<Person__c> senders = [
            SELECT Id, CRM_Account__c, INT_RegionNumber__c, INT_MunicipalityNumber__c FROM Person__c 
            WHERE CRM_Account__c IN :senderAccountIdToSms.keySet()
        ];

        List<Id> queueIds = getQueueIdsFromSenders(senders);
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);    

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyDispatcher'
        ];

        Integer index = 0;

        for(Person__c sender : senders) {
            SMS__c sms = senderAccountIdToSms.get(sender.CRM_Account__c);
            String title = 'Melding fra ' + sender.Name;
            String body = sms.Message__c;

            Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
                title,
                body,
                notificationType.Id,
                sms.Id
            );

            HOT_NotificationHandler.sendNotification(
                notification,
                new Set<String>{(String) groupByQueue.get(queueIds[index])},
                (SObject) sms
            );
            index++;
        }
    }

    

    
    @TestVisible
    private static List<Id> getQueueIdsFromSenders(List<Person__c> senders) {

        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer senderIndex = 0;

        for(Person__c sender : senders) {
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
        for(Person__c sender : senders) {
            ApexSharingRuleWrapper rule = indexToSharingRule.get(senderIndex);
            if(rule != null) {
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
        return sms.Account__c != null 
            && sms.Domain__c == 'HOT' 
            && sms.Type__c == 'Incoming SMS' 
            && sms.Recipient__c == DISPATCH_INCOMING_NUMBER;
    }
}