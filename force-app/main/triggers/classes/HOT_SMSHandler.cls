public without sharing class HOT_SMSHandler extends MyTriggers {
    public override void onBeforeInsert() {
        routeSMSToQueue((List<SMS__c>) records);
    }
    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<SMS__c> SMSToChangeOwnerToArchive = new List<SMS__c>();
        for (SMS__c sms : (List<SMS__c>) records) {
            if (
                triggerOldMap.get(sms.Id).get('HOT_DelPol_IsHideRecord__c') !== sms.HOT_DelPol_IsHideRecord__c &&
                sms.HOT_DelPol_IsHideRecord__c &&
                sms.Domain__c == 'HOT'
            ) {
                SMSToChangeOwnerToArchive.add(sms);
            }
        }
        if (SMSToChangeOwnerToArchive.size() > 0) {
            HOT_Utility.setArchiveAsOwner(SMSToChangeOwnerToArchive);
        }
    }

    public override void onAfterInsert() {
        List<SMS__c> incomingSMS = new List<SMS__c>();
        for (SMS__c sms : (List<SMS__>) records) {
            if (sms.Type__c == 'Incoming SMS' && sms.Domain__c == 'HOT') {
                incomingSMS.add(sms);
            }
        }
        if (incomingSMS.size() > 0) {
            HOT_IncomingSMSNotification.notifyDispatchersOnIncomingSMS(incomingSMS);
        }
    }

    public void routeSMSToQueue(List<SMS__c> messages) {
        Set<Id> sendersAccountId = new Set<Id>();
        for (SMS__c message : messages) {
            if (message.Account__c != null) {
                sendersAccountId.add(message.Account__c);
            }
        }
        List<Person__c> senders = [
            SELECT Id, CRM_Account__c, INT_RegionNumber__c, INT_MunicipalityNumber__c, CRM_FullName__c
            FROM Person__c
            WHERE CRM_Account__c IN :sendersAccountId
        ];
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

        Map<Integer, ApexSharingRuleWrapper> ruleByPersonId = RecordOwnerService.getQueuesAndNavUnits(
            wrappers,
            'Person__c'
        );

        Integer i = 0;
        Group adminGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HOT_Tolk_Admin' LIMIT 1];
        for (SMS__c sms : messages) {
            ApexSharingRuleWrapper rule = ruleByPersonId.get(i);
            if (rule == null) {
                sms.OwnerId = adminGroup.Id;
            } else {
                sms.OwnerId = rule.queueId;
                i++;
            }
        }
    }
}
