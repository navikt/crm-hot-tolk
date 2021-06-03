public without sharing class HOT_WageClaimHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<HOT_WageClaim__c> availableOnWageWageClaims = new List<HOT_WageClaim__c>();
        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (wageClaim.Type__c == 'Available on Wage') {
                availableOnWageWageClaims.add(wageClaim);
            }
        }
        if (availableOnWageWageClaims.size() > 0) {
            createResourceAbsences(availableOnWageWageClaims);
        }
    }
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_WageClaim__c> retractedWageClaims = new List<HOT_WageClaim__c>();
        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (
                wageClaim.Status__c != triggerOldMap.get(wageClaim.Id).get('Status__c') &&
                wageClaim.Status__c == 'Retracted Availability'
            ) {
                retractedWageClaims.add(wageClaim);
            }
        }
        if (retractedWageClaims.size() > 0) {
            deleteResourceAbsences(retractedWageClaims);
        }
    }

    public static void createResourceAbsences(List<HOT_WageClaim__c> wageClaims) {
        Set<String> resourceAbsenceFields = Schema.SObjectType.ResourceAbsence.fields.getMap().keySet();
        List<ResourceAbsence> resourceAbsences = new List<ResourceAbsence>();
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            ResourceAbsence resourceAbsence = new ResourceAbsence();
            resourceAbsence.Start = wageClaim.StartTime__c;
            resourceAbsence.End = wageClaim.EndTime__c;
            resourceAbsence.ResourceId = wageClaim.ServiceResource__c;
            resourceAbsence.Type = 'Available on Wage';
            resourceAbsence.HOT_WageClaim__c = wageClaim.Id;
            if (resourceAbsenceFields.contains('fsl__gantt_color__c')) {
                resourceAbsence.put('FSL__Gantt_Color__c', '#00ff00');
            }
            resourceAbsences.add(resourceAbsence);
        }
        insert resourceAbsences;
    }

    public static void deleteResourceAbsences(List<HOT_WageClaim__c> wageClaims) {
        delete [SELECT Id FROM ResourceAbsence WHERE HOT_WageClaim__c IN :wageClaims];
    }
}
