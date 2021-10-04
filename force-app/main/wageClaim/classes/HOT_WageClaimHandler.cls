public without sharing class HOT_WageClaimHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<Id> wageClaimsWithParent = new List<Id>();
        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (wageClaim.ParentWageClaim__c != null) {
                wageClaimsWithParent.add(wageClaim.Id);
            }
        }
        if (wageClaimsWithParent.size() > 0) {
            setFieldsBasedOnParent(wageClaimsWithParent);
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
        try {
            update childWageClaims;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void setFieldsBasedOnParent(List<Id> wageClaimIds) {
        List<HOT_WageClaim__c> wageClaims = [
            SELECT
                Id,
                AssignmentType__c,
                ServiceAppointment__c,
                ServiceResource__c,
                ServiceTerritory__c,
                WorkType__c,
                ParentWageClaim__r.AssignmentType__c,
                ParentWageClaim__r.ServiceAppointment__c,
                ParentWageClaim__r.ServiceResource__c,
                ParentWageClaim__r.ServiceTerritory__c,
                ParentWageClaim__r.WorkType__c
            FROM HOT_WageClaim__c
            WHERE Id IN :wageClaimIds
        ];
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            wageClaim.ServiceAppointment__c = wageClaim.ParentWageClaim__r.ServiceAppointment__c;
            wageClaim.ServiceTerritory__c = wageClaim.ParentWageClaim__r.ServiceTerritory__c;
            wageClaim.WorkType__c = wageClaim.ParentWageClaim__r.WorkType__c;
        }
        try {
            update wageClaims;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
}
