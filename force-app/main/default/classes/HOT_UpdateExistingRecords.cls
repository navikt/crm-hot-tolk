public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select Id, INT_MunicipalityNumber__c, CRM_Region__c FROM Person__c WHERE INT_MunicipalityNumber__c != null AND INT_IsHasTombstone__c = false'
        );
    }

    public void execute(Database.BatchableContext bc, List<Person__c> records) {
        Set<String> regionCodes = new Set<String>();
        for (Person__c p : records) {
            String regionCode = p.INT_MunicipalityNumber__c.substring(0, 2);
            regionCodes.add(regionCode);
        }

        List<Common_Code__c> validRegionCodes = [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Fylke' AND CRM_Active__c = TRUE AND CRM_Code__c IN :regionCodes
        ];

        Map<String, Id> regionAssociations = new Map<String, Id>();
        for (Common_Code__c validRegionCode : validRegionCodes) {
            regionAssociations.put(validRegionCode.CRM_Code__c, validRegionCode.Id);
        }
        List<Person__c> personsToUpdate = new List<Person__c>();
        for (Person__c p : records) {
            String regionCode = p.INT_MunicipalityNumber__c.substring(0, 2);
            if (regionAssociations.containsKey(regionCode)) {
                p.CRM_Region__c = regionAssociations.get(regionCode);
            } else {
                p.CRM_Region__c = null;
            }
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
