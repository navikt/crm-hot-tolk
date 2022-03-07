public without sharing class HOT_SMSHandler extends MyTriggers {
    public override void onBeforeInsert() {
    }

    public override void onAfterInsert() {
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<SMS__c> SMSToChangeOwnerToArchive  = new List<SMS__c>();

        for (SMS__c sms : (List<SMS__c>) records) {
            if (
                triggerOldMap.get(sms.Id).get('HOT_IsSMSHidden__c') !== sms.HOT_IsSMSHidden__c &&
                sms.HOT_IsSMSHidden__c
            ) {
                SMSToChangeOwnerToArchive .add(sms);
            }
        }

        if (SMSToChangeOwnerToArchive .size() > 0) {
            setArchiveAsOwner(SMSToChangeOwnerToArchive );
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
    }

    public static void setArchiveAsOwner(List<SMS__c> records) {
        QueueSobject archive = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = 'HOT Arkiv' LIMIT 1];

        for (SMS__c sms : records) {
            sms.OwnerId = archive.QueueId;
        }
    }
}
