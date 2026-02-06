public without sharing class HOT_WageClaimHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Map<HOT_WageClaim__c, Id> wageClaimsWithServiceResource = new Map<HOT_WageClaim__c, Id>();
        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (wageClaim.ServiceResource__c != null) {
                // Should never be null
                wageClaimsWithServiceResource.put(wageClaim, wageClaim.ServiceResource__c);
            }
        }
        if (!wageClaimsWithServiceResource.isEmpty()) {
            setServiceTerritoryBasedOnServiceResource(wageClaimsWithServiceResource);
        }
    }
    public override void onAfterInsert() {
        List<Id> wageClaimsWithParent = new List<Id>();
        Map<HOT_WageClaim__c, Id> wageClaimsWithServiceResource = new Map<HOT_WageClaim__c, Id>();

        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (wageClaim.ParentWageClaim__c != null) {
                wageClaimsWithParent.add(wageClaim.Id);
            }
            if (wageClaim.ServiceResource__c != null) {
                // Should never be null
                wageClaimsWithServiceResource.put(wageClaim, wageClaim.ServiceResource__c);
            }
        }
        if (wageClaimsWithParent.size() > 0) {
            setFieldsBasedOnParent(wageClaimsWithParent);
        }
        if (!wageClaimsWithServiceResource.isEmpty()) {
            createShiftAndSetLookup(wageClaimsWithServiceResource.keySet());
        }
    }
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_WageClaim__c> retractedWageClaims = new List<HOT_WageClaim__c>();
        List<HOT_WageClaim__c> closedWageClaims = new List<HOT_WageClaim__c>();
        for (HOT_WageClaim__c wageClaim : (List<HOT_WageClaim__c>) records) {
            if (
                wageClaim.Status__c != triggerOldMap.get(wageClaim.Id).get('Status__c') &&
                wageClaim.Status__c == 'Retracted Availability'
            ) {
                retractedWageClaims.add(wageClaim);
            }
            if (
                wageClaim.Status__c != triggerOldMap.get(wageClaim.Id).get('Status__c') &&
                wageClaim.Status__c != 'Open'
            ) {
                closedWageClaims.add(wageClaim);
            }
        }
        if (retractedWageClaims.size() > 0) {
            retractChildWageClaims(retractedWageClaims);
        }
        if (closedWageClaims.size() > 0) {
            deleteShifts(closedWageClaims);
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
        HOT_DatabaseOperations.updateRecords(childWageClaims);
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
        HOT_DatabaseOperations.updateRecords(wageClaims);
    }

    private static void setServiceTerritoryBasedOnServiceResource(
        Map<HOT_WageClaim__c, Id> wageClaimWithServiceResourceMap
    ) {
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [
                SELECT Id, HOT_ServiceTerritory__c
                FROM ServiceResource
                WHERE Id IN :wageClaimWithServiceResourceMap.values()
            ]
        );

        for (HOT_WageClaim__c wageClaim : wageClaimWithServiceResourceMap.keySet()) {
            wageClaim.ServiceTerritory__c = serviceResources.get(wageClaim.ServiceResource__c).HOT_ServiceTerritory__c;
        }
    }

    public static void createShiftAndSetLookup(Set<HOT_WageClaim__c> wageClaims) {
        List<Shift> shifts = new List<Shift>();
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            Shift shift = new Shift();
            shift.StartTime = wageClaim.StartTime__c;
            shift.EndTime = wageClaim.EndTime__c;
            shift.ServiceResourceId = wageClaim.ServiceResource__c;
            shift.Label = 'Ledig på lønn: ' + wageClaim?.Name;
            shift.HOT_WageClaim__c = wageClaim.Id;
            shifts.add(shift);
        }
        insert shifts;
    }
    public static void deleteShifts(List<HOT_WageClaim__c> wageClaims) {
        List<Shift> shifts = [SELECT Id FROM Shift WHERE HOT_WageClaim__c IN :wageClaims];
        if (shifts.size() > 0) {
            delete shifts;
        }
    }
}
