public without sharing class CRM_MessageReferenceHandler extends MyTriggers {
    public override void onBeforeInsert() {
        for (Message__c msg : (List<Message__c>) Records) {
            msg.CRM_API_Reference__c = CRM_ReferenceUtil.generateReference(msg);
        }
    }
}
