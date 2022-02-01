public without sharing class HOT_ShiftHandler extends MyTriggers {
    public override void onBeforeInsert() {
        for (Shift shift : (List<Shift>) records) {
            if (shift.CRM_ServiceResourceDomain__c = 'HOT') {
                shift.TimeSlotType = 'Extended';
            }
        }
    }
}
