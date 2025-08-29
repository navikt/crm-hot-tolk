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
        Map<Id, String> territoryMap = HOT_ShiftHandler.getTerritoryeBySrId(shifts);
        for (Shift shift : shifts) {
            shift.ServiceTerritoryId = territoryMap.get(shift.ServiceResourceId);
            shift.TimeSlotType = 'Extended';
            shift.CRM_Domain__c = 'HOT';
        }
    }

    private static Map<Id, String> getTerritoryeBySrId(List<Shift> shifts) {
        Map<Id, String> serviceTerritoryByServiceResourceId = new Map<Id, String>();
        Set<Id> serviceResourceIds = new Set<Id>();
        for (Shift shiftRecord : shifts) {
            if (shiftRecord.ServiceResourceId != null) {
                serviceResourceIds.add(shiftRecord.ServiceResourceId);
            }
        }

        Map<Id, ServiceResource> serviceResourcesMap = new Map<Id, ServiceResource>(
            [SELECT Id, HOT_ServiceTerritory__c FROM ServiceResource WHERE Id IN :serviceResourceIds]
        );
        for (Id srId : serviceResourcesMap.keySet()) {
            serviceTerritoryByServiceResourceId.put(srId, serviceResourcesMap.get(srId)?.HOT_ServiceTerritory__c);
        }
        return serviceTerritoryByServiceResourceId;
    }
}
