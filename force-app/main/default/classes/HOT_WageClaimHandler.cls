public without sharing class HOT_WageClaimHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<Id> parentWageClaimIds = new List<Id>();
        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (wageClaim.ParentWageClaim__c != null) {
                parentWageClaimIds.add(wageClaim.ParentWageClaim__c);
            }
        }
        if (parentWageClaimIds.size() > 0) {
            setParentFieldTrue(parentWageClaimIds);
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
            retractChildWageClaims(retractedWageClaims);
        }
    }

    public static void retractChildWageClaims(List<HOT_WageClaim__c> wageClaims) {
        List<HOT_WageClaim__c> childWageClaims = [
            SELECT Id, Status__c
            FROM HOT_WageClaim__c
            WHERE ParentWageClaim__c IN :wageClaims
        ];
        for (HOT_WageClaim__c wageClaim : childWageClaims) {
            wageClaim.Status__c = 'Retracted Availability';
        }
        update childWageClaims;
    }

    public static void setParentFieldTrue(List<Id> wageClaimIds) {
        List<HOT_WageClaim__c> wageClaims = [SELECT Id, IsParent__c FROM HOT_WageClaim__c WHERE Id IN :wageClaimIds];
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            wageClaim.IsParent__c = true;
        }
        update wageClaims;
    }
}
