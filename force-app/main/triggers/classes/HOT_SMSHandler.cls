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
    }
}
