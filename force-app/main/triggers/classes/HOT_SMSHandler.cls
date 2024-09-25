public without sharing class HOT_SMSHandler extends MyTriggers {
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
        HOT_IncomingSMSNotification.notifyDispatchersOnIncomingSMS((List<SMS__c>) records);
        routeSMSToQueue((List<SMS__c>) records);
    }

    public void routeSMSToQueue(List<SMS__c> messages) {
        Set<Id> sendersAccountId = new Set<Id>();
        for (SMS__c message : messages) {
            if (request.Account__c != null) {
                sendersAccountId.add(message.Account__c);
            }
        }
        List<Person__c> senders = [
            SELECT Id, CRM_Account__c, INT_RegionNumber__c, INT_MunicipalityNumber__c, CRM_FullName__c
            FROM Person__c
            WHERE CRM_Account__c IN :sendersAccountId
        ];
        List<Id> queueIds = HOT_IncomingSMSNotification.getQueueIdsFromSenders(senders);
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Integer index = 0;
        for (Person__c sender : senders) {
            for (SMS__c sms : messages) {
                sms.OwnerId = groupByQueue.get(queueIds[index]);
            }
            index++;
        }
        update messages;
    }
}
