public without sharing class HOT_ShiftHandler extends MyTriggers {
    public override void onBeforeInsert() {
        List<Shift> hotShifts = new List<Shift>();

        for (Shift shift : (List<Shift>) records) {
            System.debug(shift);
            if (shift.CRM_ServiceResourceDomain__c == 'HOT') {
                hotShifts.add(shift);
            }
        }
        if (hotShifts.size() > 0) {
            setDefaultFieldValues(hotShifts);
        }
    }

    private static void setDefaultFieldValues(List<Shift> shifts) {
        for (Shift shift : shifts) {
            shift.TimeSlotType = 'Extended';
            shift.CRM_Domain__c = 'HOT';
        }
    }
}
