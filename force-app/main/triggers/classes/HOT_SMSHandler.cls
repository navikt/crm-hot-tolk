public without sharing class HOT_SMSHandler extends MyTriggers {
    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<SMS__c> SMSToChangeOwnerToArchive = new List<SMS__c>();
        for (SMS__c sms : (List<SMS__c>) records) {
            if (
                triggerOldMap.get(sms.Id).get('HOT_IsSMSHidden__c') !== sms.HOT_IsSMSHidden__c &&
                sms.HOT_IsSMSHidden__c && sms.Domain__c == 'HOT'
            ) {
                SMSToChangeOwnerToArchive.add(sms);
            }
        }
        if (SMSToChangeOwnerToArchive .size() > 0) {
            HOT_Utility.setArchiveAsOwner(SMSToChangeOwnerToArchive, 'SMS__c');
        }
    }
}
