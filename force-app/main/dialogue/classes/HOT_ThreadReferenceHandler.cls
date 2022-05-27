public without sharing class HOT_ThreadReferenceHandler extends MyTriggers {
    public override void onBeforeInsert() {
        for (Thread__c thread : (List<Thread__c>) Records) {
            if (String.isNotBlank(thread.CRM_Henvendelse_BehandlingsId__c)) {
                thread.CRM_API_Reference__c = thread.CRM_Henvendelse_BehandlingsId__c;
            } else {
                thread.CRM_API_Reference__c = HOT_ReferenceUtil.generateReference(thread);
            }
        }
    }
}
